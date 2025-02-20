package ICANN::RST::Text;
# ABSTRACT: an object representing Markdown text.
use Alien::pandoc;
use Digest::SHA qw(sha1_hex);
use Encode qw(decode_utf8);
use Env qw( @PATH );
use File::Slurp;
use File::Spec;
use IPC::Open2;
use Text::Unidecode;
use utf8;
use strict;

unshift(@PATH, Alien::pandoc->bin_dir);

my $CACHE;

sub new {
    my ($package, $text) = @_;
    return bless({'text' => $text}, $package);
}

sub text { $_[0]->{'text'} }

sub html {
    my ($self, $shift) = @_;

    return '<div class="markdown-content">'.$self->raw_html($shift).'</div>';
}

sub raw_html {
    my ($self, $shift) = @_;

    my $key = sprintf('%s.%u', sha1_hex(unidecode($self->text)), $shift);

    if (!defined($CACHE->{$key})) {
        my $f = File::Spec->catfile(File::Spec->tmpdir, $key.'.html');

        unless (-e $f) {
            my @cmd = (qw(pandoc -f markdown -t html -o), $f);

            push(@cmd, sprintf('--shift-heading-level-by=%u', $shift)) if ($shift > 0);

            my $pid = open2(undef, my $in, @cmd);

            $in->binmode(':encoding(UTF-8)');
            $in->print($self->text),
            $in->close;

            waitpid($pid, 0);
        }

        $CACHE->{$key} = read_file($f, 'binmode' => ':encoding(UTF-8)');
    }

    return $CACHE->{$key};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ICANN::RST::Text - an object representing Markdown text.

=head1 VERSION

version 0.01

=head1 METHODS

=head2 new($text)

Constructor. C<$text> is a string.

=head2 html($heading_shift)

Convert to HTML. C<$heading_shift> is an integer which modifies the level of heading elements (eg a shift of 1 turns all C<h1> elements into C<h2>, C<h2> to C<h3> etc).

=head1 AUTHOR

Gavin Brown <gavin.brown@icann.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names and Number (ICANN).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
