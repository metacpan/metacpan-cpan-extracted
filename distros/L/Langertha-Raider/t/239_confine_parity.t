#!/usr/bin/env perl
# ABSTRACT: The file tools and the search tools give the same verdict on a path: they share one confinement (ADR 0023)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Langertha::Raider::FileTools qw( build_file_tools_server );
use Langertha::Raider::SearchTools;

my $tmp   = Path::Tiny->tempdir->realpath;
my $root  = $tmp->child('root');
my $extra = $tmp->child('extra');
my $other = $tmp->child('other');
$_->mkpath for $root, $extra, $other;
$root->child('in.txt')->spew("TODO in\n");
$extra->child('x.txt')->spew("TODO extra\n");
$other->child('o.txt')->spew("TODO other\n");
symlink "$other", "$root/escape";

my $confine = 1;
my @extra   = ("$extra");
my %args = (
  root        => "$root",
  extra_roots => sub { [@extra] },
  confine     => sub { $confine },
);
my $files  = build_file_tools_server(%args);
my $search = Langertha::Raider::SearchTools->new( %args, rg => 0 );

sub files_verdict {
  my ($path) = @_;
  my ($tool) = grep { $_->name eq 'list_files' } @{ $files->tools };
  my $r = $tool->code->( $tool, { path => $path } );
  return $r->{isError} && $r->{content}[0]{text} =~ /Path escapes root/ ? 'refused' : 'allowed';
}
sub search_verdict {
  my ($path) = @_;
  my $ok = eval { $search->_resolve($path); 1 };
  return $ok ? 'allowed' : $@ =~ /path escapes root/ ? 'refused' : 'other: '.$@;
}

my @cases = (
  [ '.'                          => 'allowed', 'the root' ],
  [ 'in.txt'                     => 'allowed', 'inside' ],
  [ "$extra"                     => 'allowed', 'an additional directory' ],
  [ "$other"                     => 'refused', 'a directory outside' ],
  [ '../other'                   => 'refused', 'a relative way out' ],
  [ 'escape'                     => 'refused', 'a symlink out' ],
);

for my $c (@cases) {
  my ( $path, $want, $name ) = @$c;
  is [ files_verdict($path), search_verdict($path) ], [ $want, $want ], $name;
}

$confine = 0;
is [ files_verdict("$other"), search_verdict("$other") ], [ 'allowed', 'allowed' ], 'confine off: both let it through';
$confine = 1;
@extra   = ();
is [ files_verdict("$extra"), search_verdict("$extra") ], [ 'refused', 'refused' ], 'the additional directories are asked on every call';

done_testing;
