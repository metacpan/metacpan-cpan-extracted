package Kwiki::PerlTidyBlocks;
use Kwiki::Plugin -Base;
use Kwiki::Installer -Base;
our $VERSION = '0.12';

const class_id => 'perl_tidy_blocks';
const css_file => 'perl_tidy_blocks.css';

sub register {
    my $registry = shift;
    $registry->add(prerequisite => 'cache');
    $registry->add(wafl => perl => 'Kwiki::PerlTidyBlocks::Wafl');
}

package Kwiki::PerlTidyBlocks::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    return join '',
      qq{<table class="perl_tidy_blocks"><tr><td>\n},
      $self->from_cache($self->block_text),
      qq{</td></tr></table>\n};
}

sub from_cache {
    my $source = shift;
    $self->hub->cache->process(
        sub { $self->tidy($source) }, 'perl_tidy_blocks', $source
    );
}

sub tidy {
    my $source = shift;
    require Perl::Tidy;
    my $result;
    eval {
        Perl::Tidy::perltidy(
            source      => \$source,
            destination => \$result,
            argv        => [qw( -q -html -pre -npro )],
        );
    };
    $@ ? $source : $result;
}

package Kwiki::PerlTidyBlocks;
__DATA__

=head1 NAME 

Kwiki::PerlTidyBlocks - Kwiki Perl Tidy Blocks Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/perl_tidy_blocks.css__
table.perl_mode pre {
    background-color: #FFF;
}

table.perl_mode td {
    border: 0;
}

.pd { color: #404080;} /* pod-text */
.c  { color: #404080;} /* comment */

.cm { color: #800097;} /* comma */
.co { color: #800097;} /* colon */

.h  { color: #804848;} /* here-doc-target */
.hh { color: #800000;} /* here-doc-text */
.q  { color: #800000;} /* quote */
.v  { color: #800000;} /* v-string */

.i  { color: #008080;} /* identifier */

.k  { color: #0000FF;} /* keyword */
.n  { color: #E02020;} /* numeric */

.m  { color: #C00080;} /* subroutine */
.j  { color: #C00080;} /* label */
.w  { color: #C00080;} /* bareword */

.p  { color: #800080;} /* paren */
.s  { color: #800080;} /* structure */
.sc { color: #800080;} /* semicolon */

.pu { color: #C44800;} /* punctuation */
