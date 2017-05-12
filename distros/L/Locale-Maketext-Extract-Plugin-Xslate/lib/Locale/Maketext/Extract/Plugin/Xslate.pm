package Locale::Maketext::Extract::Plugin::Xslate;
use strict;
use warnings;
use parent qw(Locale::Maketext::Extract::Plugin::Base);
our $VERSION = '0.0.3';
our $DEBUG = 0;

use Locale::Maketext::Extract;
$Locale::Maketext::Extract::Known_Plugins{xslate} = __PACKAGE__;

use Data::Dumper;

sub file_types {
    qw( tt html );
}

sub new {
    my($class, $args) = @_;
    my $extensions = delete $args->{extensions};
    my $syntax     = delete $args->{syntax} || 'TTears';
    my $self = $class->SUPER::new($extensions);
    eval "use Text::Xslate::Syntax::$syntax;"; ## no critic
    die $@ if $@;
    $self->{xslate_parser} = "Text::Xslate::Syntax::$syntax"->new($args);
    $self;
}

sub extract {
    my($self, $data) = @_;
    my $ast = $self->{xslate_parser}->parse($data);
    $self->walker($ast);
}

my $sp = '';
sub walker {
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
                            $self->add_entry($value->value, $value->line);
                        }
                    }
                }
            }
        }

        unless ($DEBUG) {
            $self->walker($sym->first);
            $self->walker($sym->second);
            $self->walker($sym->third);
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
            $self->walker($sym->first);
            $sp =~ s/^.//;

            warn "$sp second: " . $sym->second;
            $sp .= ' ';
            $self->walker($sym->second);
            $sp =~ s/^.//;

            warn "$sp third: " . $sym->third;
            $sp .= ' ';
            $self->walker($sym->third);
            $sp =~ s/^.//;

            warn $sp . '----------';
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Locale::Maketext::Extract::Plugin::Xslate - Xslate format parser

=head1 SYNOPSIS

  use Locale::Maketext::Extract;
  use Locale::Maketext::Extract::Plugin::Xslate;

  my $ext = Locale::Maketext::Extract->new(
      plugins => {
          xslate => {
              syntax     => 'TTerse',
              extensions => ['tt', 'html'],
          },
      },
      warnings => 1,
      verbose  => 1,
  );
  $ext->extract_file('tmpl/index.tt');
  $ext->compile(1);
  $ext->write_po('messages.po');

=head1 DESCRIPTION

Extracts strings to localise from L<Text::Xslate> templates.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 VALID FORMATS

Valid formats are:

=over 4

=item [% l('string') %]

=item [% l('string %1', args[, ...]) %]

=item [% IF l('string') = 'FOO' %]

=back

=head1 KNOWN FILE types

=over 4

=item .tt

=item .html

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {@} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Text::Xslate>, L<Locale::Maketext::Extract>

=head1 LICENSE

Copyright (C) Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
