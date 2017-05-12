#!/usr/bin/perl
#===============================================================================
#
#         FILE: wd_cgi.pl
#
#  DESCRIPTION:  CGI script for WebDAO project
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
#$Id: wd_cgi.pl,v 1.1 2006/10/13 12:39:09 zag Exp $

use HTML::WebDAO;
use HTML::WebDAO::CVcgi;
use HTML::WebDAO::Session;
use HTML::WebDAO::Lex;

use Data::Dumper;
use strict;

sub _parse_str_to_hash {
    my $str = shift;
    return unless $str;
    my %hash = map { split( /=/, $_ ) } split( /;/, $str );
    foreach ( values %hash ) {
        s/^\s+//;
        s/\s+^//;
    }
    \%hash;
}

my ( $store_class, $session_class, $eng_class ) = map {
    eval "require $_"
      or die $@;
    $_
  } (
    $ENV{wdStore}   || 'HTML::WebDAO::Store::Abstract',
    $ENV{wdSession} || 'HTML::WebDAO::Session',
    $ENV{wdEngine}  || 'HTML::WebDAO::Engine'
  );

my $store_obj =
  $store_class->new( %{ &_parse_str_to_hash( $ENV{wdStorePar} ) || {} } );
my $sess = $session_class->new(
    %{ &_parse_str_to_hash( $ENV{wdSessionPar} ) || {} },
    store => $store_obj,
    cv    => new HTML::WebDAO::CVcgi::,

);
$sess->set_header( -type => 'text/html; charset=utf-8' );
my ($filename) = grep { -r $_ && -f $_ } $ENV{wdIndexFile},
  "$ENV{DOCUMENT_ROOT}/$ENV{wdIndexFile}", "$ENV{DOCUMENT_ROOT}/index.xhtml";
die "$0 ERR:: file not found or can't access (wdIndexFile): $ENV{wdIndexFile}"
  unless $filename;
my $content = qq!<wD><include file="$filename"/></wD>!;
my $lex     = new HTML::WebDAO::Lex:: content => $content;

my $eng = $eng_class->new(
    %{ &_parse_str_to_hash( $ENV{wdEnginePar} ) || {} },
    lexer    => $lex,
    session  => $sess,
);
$sess->ExecEngine($eng);
$sess->destroy;

__END__

=head1 NAME

wd_cgi.pl - CGI script for WebDAO project

=head1 SETUP

    SetEnv wdIndexFile index.xhtm


=head1 SEE ALSO

http://sourceforge.net/projects/webdao, HTML::WebDAO

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2007 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
