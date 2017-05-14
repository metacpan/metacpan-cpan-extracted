# $Id: Memo.pm 1.11 Wed, 10 Dec 1997 17:58:09 -0500 jesse $

package Devel::Memo;
require 5.004;
use FreezeThaw qw(safeFreeze);

sub new($$@) {
  my ($class, $subr, @styles)=@_;
  my %cache;
  my $proto=prototype $subr;
  $proto="($proto)" if defined $proto;
  bless eval qq{
    sub $proto {$class->_exec(\$subr, \\\@styles, \\%cache, [\@_])}
  }, $class;
}

sub _exec($$$$;) {
  my ($class, $subr, $styles, $cache, $args)=@_;
  my @styles=@$styles;
  my @virtargs=@$args;
  if ($styles[-1] eq '-rest') {
    $styles[-1]='-equal';
    my $rest=[splice @virtargs, $#styles];
    push @virtargs, $rest;
  }
  die "Bad matchup of arguments: @{[scalar @virtargs]} vs. @{[scalar @styles]}"
    unless @styles==@virtargs;
  my $i; for ($i=0; $i<@virtargs; $i++) {
    $virtargs[$i]=safeFreeze($virtargs[$i]) if $styles[$i] eq '-equal';
  }
  my $key=join '', map {length($_) . ":$_"} @virtargs;
  my $val=$cache->{$key};
  $val=$cache->{$key}=[&$subr(@$args)] unless defined $val;
  wantarray ? @$val : $val->[-1];
}

1;
__END__

=head1 NAME

B<Devel::Memo> - memoize function calls

=head1 SYNOPSIS

 use Devel::Memo;
 sub number_cruncher {
   local(*tough)=new Devel::Memo sub($$@) {
     my ($arg1, $arg2, @others)=@_;
     ...calculate...
     return $some_val, $some_other_val;
   }, qw(-eq -equal -rest);
   my @result1=tough 17, [1, 2];
   my @result2=tough 15, {foo => 1}, 'bar';
   my @result3=tough 15, {foo => 1}, 'bar'; # Faster!
 }

=head1 DESCRIPTION

A B<Devel::Memo> object is defined as a subroutine reference to do some sort of calculation,
together with a simple sort of prototype. The elements of the prototype may be: B<-eq>,
indicating a simple scalar argument (number or string); B<-equal>, indicating an
argument held in a scalar but possibly containing references, which will be examined in
a recursive fashion; and B<-rest>, meaning that zero or more extra arguments may appear,
which should be compared both in number, and individually as with B<-equal>.

The object is just a blessed subroutine reference, so you can call it directly or assign it to a typeglob to make it look like any other function call. The difference is that the object maintains an internal cache of previous invocations and their results, and returns a previous result directly if a set of arguments is ever duplicated (as defined by the "prototype", above). The cache is freed when the object leaves scope.

The implementing function is always called in array context; if the object is called in
scalar context, the last value is returned.

=head2 Implementation

B<FreezeThaw> is used.

=head1 BUGS AND RESTRICTIONS

There is no way to access instance data without changing this module, as it is
completely private to the code reference.

Overhead in creating the hash key, etc. will make this module not worth your while
unless the operations to be memoized are fairly time-consuming. An XSUB version would be
nice...

Any bugs in B<FreezeThaw> will presumably affect this module.

The use of B<FreezeThaw::safeFreeze> actually oversteps B<FreezeThaw>'s documented
guaranteed behavior in that it assumes that B<safeFreeze> will return the same result
for structurally equivalent arguments. Currently (B<FreezeThaw> as in
F<ILYAZ/etext/etext1.6.2.tar.gz>) this is in fact the case, and it will probably
remain so. If not, performance will suffer but the results should not be incorrect.

=head1 AUTHORS

Jesse Glick, B<jglick@sig.bsh.com>

=head1 SEE ALSO

L<FreezeThaw(3P)>.

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$, release $DevelMemoRelease$. $Copyright$"$>
F<Devel-Memo/lib/Devel/Memo.pm> last modified Wed, 10 Dec 1997 17:58:09 -0500, release 0.004. Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
