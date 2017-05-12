#!/usr/bin/perl
use strict;
use warnings;
use Locale::Maketext::Extract::Run 'xgettext';

=head1 NAME

xgettext-xsl.pl - Wrapper for use of Locale::Maketext::Extract::Plugin::XSL

=head1 SYNOPSIS

perl examples/xgettext-xsl.pl t/i18ntest.xsl

=head1 DESCRIPTION

This example provides a simple wrapper script to enable the
L<Locale::Maketext::Extract::Plugin::XSL> plugin for xgettext.pl

=cut

system(qq[perldoc "xgettext.pl"]) unless @ARGV;

unshift(@ARGV, '-P','Locale::Maketext::Extract::Plugin::XSL');
exit xgettext(@ARGV);


