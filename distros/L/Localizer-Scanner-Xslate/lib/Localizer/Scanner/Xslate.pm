package Localizer::Scanner::Xslate;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.05";

sub DEBUG () { 0 }

use Localizer::Dictionary;

use Class::Accessor::Lite 0.05 (
    ro => [qw(parser)],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $self = bless { }, $class;
    my $syntax = $args{syntax} || 'TTerse';
    $self->{parser} = $self->_build_parser($syntax);

    return $self;
}

our $RESULT;
our $FILENAME;

sub _build_parser {
    my ($self, $syntax) = @_;

    eval "use Text::Xslate::Syntax::${syntax};"; ## no critic
    die $@ if $@;

    "Text::Xslate::Syntax::${syntax}"->new(),
}

sub scan {
    my($self, $result, $filename, $data) = @_;
    my $ast = $self->parser->parse($data);
    local $FILENAME = $filename;
    local $RESULT = $result;
    $self->_walker($ast);
    return $result;
}

sub scan_file {
    my ($self, $result, $filename) = @_;
    open my $fh, '<:encoding(utf-8)', $filename
        or die "Cannot open file '$filename' for reading: $!";
    my $data = do { local $/; <$fh> };
    return $self->scan($result, $filename, $data);
}

my $sp = '';
sub _walker {
    my($self, $ast) = @_;
    $ast = [ $ast ] if $ast && ref($ast) eq 'Text::Xslate::Symbol';
    return unless $ast && ref($ast) eq 'ARRAY';

    for my $sym (@{ $ast }) {

        if ($sym->arity eq 'call' && $sym->value eq '(') {
            my $first = $sym->first;
            if ($first && ref($first) eq 'Text::Xslate::Symbol') {
                if ($first->arity eq 'variable' && $first->value eq 'l') {
                    my $second = $sym->second;
                    if ($second && ref($second) eq 'ARRAY' && $second->[0] && ref($second->[0]) eq 'Text::Xslate::Symbol') {
                        my $value = $second->[0];
                        if ($value->arity eq 'literal') {
                            $RESULT->add_entry_position($value->value, $FILENAME, $value->line);
                        }
                    }
                }
            }
        }

        unless (DEBUG) {
            $self->_walker($sym->first);
            $self->_walker($sym->second);
            $self->_walker($sym->third);
        } else {
            warn "$sp id: " . $sym->id;
            warn "$sp line: " . $sym->line;
            warn "$sp ldp: ". $sym->lbp;
            warn "$sp udp: ". $sym->ubp;
            warn "$sp type: ". $sym->type;

            warn "$sp arity: ". $sym->arity;
            warn "$sp assignment: ". $sym->assignment;
            warn "$sp value: ". $sym->value;

            warn "$sp first: " . $sym->first;
            $sp .= ' ';
            $self->_walker($sym->first);
            $sp =~ s/^.//;

            warn "$sp second: " . $sym->second;
            $sp .= ' ';
            $self->_walker($sym->second);
            $sp =~ s/^.//;

            warn "$sp third: " . $sym->third;
            $sp .= ' ';
            $self->_walker($sym->third);
            $sp =~ s/^.//;

            warn $sp . '----------';
        }
    }
}

1;
__END__

=for stopwords xslate foobar

=encoding utf-8

=head1 NAME

Localizer::Scanner::Xslate - Scanner for L<Text::Xslate> style file

=head1 SYNOPSIS

    use Localizer::Dictionary;
    use Localizer::Scanner::Xslate;

    my $result  = Localizer::Dictionary->new();
    my $scanner = Localizer::Scanner::Xslate->new(
        syntax => 'TTerse',
    );
    $scanner->scan_file($result, 'path/to/xslate.html');

=head1 DESCRIPTION

Localizer::Scanner::Xslate is localization tag scanner for Xslate templates.

This module finds C<< [% l("foo") %] >> style tags from xslate template files.

=head1 METHODS

=over 4

=item * Localizer::Scanner::Xslate(%args | \%args)

Constructor. It makes scanner instance.

e.g.

    my $ext = Localizer::Scanner::Xslate->new(
        syntax => 'Kolon', # => will use Text::Xslate::Syntax::Kolon
    );

=over 8

=item syntax: String

Specify syntax of L<Text::Xslate>. Default, this module uses L<Text::Xslate::Syntax::TTerse>.

=back

=item * $scanner->scan_file($result, $filename)

Scan file which is written by xslate.
C<$result> is the instance of L<Localizer::Dictionary> to store results.
C<$filename> is file name of the target to scan.

For example, if target file is follows;

    [% IF xxx == l('term') %]
    [% END %]

    [% l('hello') %]

Scanner uses C<l('foobar')> as C<msgid> (in this case, 'foobar' will be C<msgid>).

C<$result> will be like a following;

    {
        'term' => {
            'position' => [ [ 'path/to/xslate.html', 1 ] ]
        },
        'hello' => {
            'position' => [ [ 'path/to/xslate.html', 4 ] ]
        }
    }

=item * $scanner->scan($result, $filename, $data)

This method is almost the same as C<scan_file()>.
This method does not load file contents, it uses C<$data> as file contents instead.

=back

=head1 SEE ALSO

This module is based on L<Locale::Maketext::Extract::Plugin::Xslate>.

=head1 LICENSE

Copyright (C) Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazuhiro Osawa, Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=cut

