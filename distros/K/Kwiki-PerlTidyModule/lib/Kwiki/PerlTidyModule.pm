package Kwiki::PerlTidyModule;
use Kwiki::Plugin -Base;
use Kwiki::Installer -Base;
our $VERSION = '0.12';

const class_id => 'perl_tidy_module';
const css_file => 'perl_tidy_module.css';

sub register {
    my $registry = shift;
    $registry->add(prerequisite => 'cache');
    $registry->add(wafl => perl_tidy_module => 'Kwiki::PerlTidyModule::Wafl');
}

package Kwiki::PerlTidyModule::Wafl;
use Spoon::Formatter;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my $thing = $self->arguments;
    my $file_name = $thing =~ /^[a-z0-9_]+$/
    ? $self->file_from_class_id($thing)
    : $thing =~ /^[\w\:]+$/
      ? $self->file_from_module($thing)
      : '';
    return $self->wafl_error
      unless $file_name;
    return join '',
      qq{<table class="perl_tidy_module"><tr><td><pre>\n},
      $self->tidy($file_name),
      qq{</pre></td></tr></table>\n};
}

sub file_from_class_id {
    my $class_id = shift;
    my $object = eval {$self->hub->$class_id}
      or return;
    $self->file_from_module(ref($object));
}

sub file_from_module {
    my $module = shift;
    eval "use $module; 1"
      or return;
    $module =~ s/::/\//g;
    $module .= '.pm';
    return $INC{$module};
}

sub tidy {
    my $file_name = shift;
    my $source = io($file_name)->slurp;
    return $self->escape_html($source)
      unless $file_name =~ /\.(pl|pm|cgi|t|dd)$/;
    my $html = $self->hub->cache->process(
        sub { $self->cache_this($source) }, 'perl_tidy_module', $source
    );
    $html =~ s/^<pre>\s*(.*)\s*<\/pre>\s*\z/$1/s;
    return $html;
}

sub cache_this {
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

package Kwiki::PerlTidyModule;
__DATA__

=head1 NAME 

Kwiki::PerlTidyModule - Kwiki Perl Tidy Module Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/perl_tidy_module.css__
table.perl_tidy_module {
    border-collapse: collapse;
    margin: .5em;
}

table.perl_tidy_module td {
    border: 1px;
    border-style: solid;
    padding: .5em;
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
