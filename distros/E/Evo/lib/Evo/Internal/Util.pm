package Evo::Internal::Util;
use strict;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Carp qw(carp croak);
use B qw(svref_2object);

our $RX_PKG_NOT_FIRST = qr/[0-9A-Z_a-z]+(?:::[0-9A-Z_a-z]+)*/;
our $RX_PKG           = qr/^[A-Z_a-z]$RX_PKG_NOT_FIRST*$/;


use constant SUBRE => qr/^[a-zA-Z_]\w*$/;
sub check_subname { $_[0] =~ SUBRE }

# usefull?
sub find_caller_except ($skip_ns, $i, $caller) {
  while ($caller = (caller($i++))[0]) {
    return $caller if $caller ne $skip_ns;
  }
}

sub monkey_patch ($pkg, %hash) {
  no strict 'refs';    ## no critic
  *{"${pkg}::$_"} = $hash{$_} for keys %hash;
}

#todo: decide what to do with empty subroutins
sub monkey_patch_silent ($pkg, %hash) {
  no strict 'refs';    ## no critic
  no warnings 'redefine';
  my %restore;
  foreach my $name (keys %hash) {
    $restore{$name} = *{"${pkg}::$name"}{CODE};
    warn "Can't delete empty ${pkg}::$name" and next unless $hash{$name};
    *{"${pkg}::$name"} = $hash{$name};
  }
  \%restore;
}

# returns a package where code was declared and a name
# ->CONST not documented, but exists in B::CV and defined in /CORE/cv.h as
# define CvCONST(cv)		(CvFLAGS(cv) & CVf_CONST)
# this flag is used by Evo::Class to determine that constants should be inherited
sub code2names($r) {
  my $sv    = svref_2object($r);
  my $gv    = $sv->GV;
  my $stash = $gv->STASH;
  ($stash->NAME, $gv->NAME, $sv->CONST);
}

sub names2code ($pkg, $name) {
  no strict 'refs';    ## no critic
  *{"${pkg}::$name"}{CODE};
}


sub list_symbols($pkg) {
  no strict 'refs';    ##no critic
  grep { $_ =~ /^[a-zA-Z_]\w*$/ } keys %{"${pkg}::"};
}

#sub undef_symbols($ns) {
#  no strict 'refs';    ## no critic
#  undef *{"${ns}::$_"} for list_symbols($ns);
#}


#sub uniq {
#  my %seen;
#  return grep { !$seen{$_}++ } @_;
#}

# returns a subroutine than can pretend a code in the other package/file/line
sub inject(%opts) {
  my ($package, $filename, $line, $code) = @opts{qw(package filename line code)};

  ## no critic
  (
    eval qq{package $package;
#line $line "$filename"
    sub { \$code->(\@_) }
}
  );
}

#sub find_subnames ($pkg, $code) {
#  no strict 'refs';    ## no critic
#  my %symbols = %{$pkg . "::"};
#
#  # because use constant adds refs to package symbols hash
#  grep { !ref($symbols{$_}) && (*{$symbols{$_}}{CODE} // 0) == $code } keys %symbols;
#}


sub _parent ($caller) {
  my @arr = split /::/, $caller;
  pop @arr;
  join '::', @arr;
}

sub resolve_package ($caller, $pkg) {

  return $pkg if $pkg =~ $RX_PKG;

  return "Evo::$1" if $pkg =~ /^\-($RX_PKG_NOT_FIRST)$/;

  # parent. TODO: many //
  if ($pkg =~ /^\/(.*)$/) {
    my $rest   = $1;
    my $parent = _parent($caller)
      or croak "Can't resolve $pkg: can't find parent of caller $caller";

    return "$parent$rest" if "$parent$rest" =~ /^$RX_PKG$/;
  }

  return "${caller}::$1" if $pkg =~ /^::($RX_PKG_NOT_FIRST)$/;

  croak "Can't resolve $pkg for caller $caller";
}


sub suppress_carp ($me, $caller) {
  no strict 'refs';    ## no critic
  push @{"${caller}::CARP_NOT"}, $me if !grep { $_ eq $me } @{"${caller}::CARP_NOT"};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Internal::Util

=head1 VERSION

version 0.0403

=head1 DESCRIPTION

This is bare internal collection, this functions are used by Exporter, so we need this module and can't export them

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
