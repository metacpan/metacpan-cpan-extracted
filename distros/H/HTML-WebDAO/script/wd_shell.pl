#!/usr/bin/perl
#===============================================================================
#
#         FILE: wd_shell.pl
#
#  DESCRIPTION:  shell script for WebDAO project
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================
#$Id: wd_shell.pl,v 1.2 2006/10/27 08:59:08 zag Exp $

use strict;
use warnings;
use Carp;
use HTML::WebDAO;
use HTML::WebDAO::SessionSH;
use HTML::WebDAO::Store::Abstract;
use HTML::WebDAO::Lex;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

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
    $ENV{wdSession} || 'HTML::WebDAO::SessionSH',
    $ENV{wdEngine}  || 'HTML::WebDAO::Engine'
  );

my ( $help, $man, $sess_id );
my %opt = ( help => \$help, man => \$man, sid => \$sess_id );   #meta=>\$meta,);
GetOptions( \%opt, 'help|?', 'man', 'f=s', 'sid|s=s' )
  or pod2usage(2);
pod2usage(1) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

if ( my $file = $opt{f} ) {
    pod2usage( -exitstatus => 2, -message => "Not exists file [-f] : $file" )
      unless -e $file;
}
else {
    pod2usage( -exitstatus => 2, -message => 'Need  file [-f] !' )
      unless $ENV{wdIndexFile} && -e $ENV{wdIndexFile};
}
my $evl_file = shift @ARGV;
pod2usage( -exitstatus => 2, -message => 'No file give or non exists ' )
  unless $evl_file and -e $evl_file;

open FH, "<$evl_file" or die $!;
my $code;
{ local $/; $/ = undef; $code = <FH> }
close FH;

#check syntax
my $eng;
my $evaled_sub;
{
    eval "\$evaled_sub = sub { $code } ";
}
croak $@ if $@;

foreach my $sname ('__DIE__') {
    $SIG{$sname} = sub {
        return if (caller(1))[3] =~ /eval/;
        push @_, "STACK:" . Dumper( [ map { [ caller($_) ] } ( 1 .. 3 ) ] );
        print "PID: $$ $sname: @_";
      }
}

my $store_obj =
  $store_class->new( %{ &_parse_str_to_hash( $ENV{wdStorePar} ) || {} } );
my $sess = $session_class->new(
        %{ &_parse_str_to_hash( $ENV{wdSessionPar} ) || {} },
        store => $store_obj,
);
$sess->U_id($sess_id);
my ($filename) = grep { -r $_ && -f $_ } $ENV{wdIndexFile} || $opt{f};
die "$0 ERR:: file not found or can't access (wdIndexFile): $ENV{wdIndexFile}"
  unless $filename;
my $content = qq!<wD><include file="$filename"/></wD>!;
my $lex = new HTML::WebDAO::Lex:: content => $content;
$eng = $eng_class->new(
    %{ &_parse_str_to_hash( $ENV{wdEnginePar} ) || {} },
    lexer    => $lex,
    session  => $sess,
);
$sess->ExecEngine($eng);
#run
{
    eval "\$evaled_sub->()";
}
$sess->destroy;
croak STDERR $@ if $@;
print "\n";

#$sess->ExecEngine($eng);

=head1 NAME

  wd_shell.pl  - command line tool for developing and debuging

=head1 SYNOPSIS

  wd_shell.pl [options] file.pl

   options:

    -help  - print help message
    -man   - print man page
    -f file    - set root [x]html file 

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits

=item B<-man>

Prints manual page and exits

=item B<-f> L<filename>

Set L<filename> set root [x]html file  for load domain

=back

=head1 DESCRIPTION

B<wd_shell.pl>  - tool for debug .

=head1 SEE ALSO

http://sourceforge.net/projects/webdao, HTML::WebDAO

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2000-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

