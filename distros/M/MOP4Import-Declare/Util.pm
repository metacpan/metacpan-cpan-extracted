package MOP4Import::Util;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Data::Dumper;

use Exporter qw/import/;

sub globref {
  my $pack_or_obj = shift;
  my $pack = ref $pack_or_obj || $pack_or_obj;
  my $symname = join("::", $pack, @_);
  no strict 'refs';
  \*{$symname};
}

sub symtab {
  *{globref(shift, '')}{HASH}
}

sub fields_hash {
  my $sym = fields_symbol(@_);
  # XXX: return \%{*$sym}; # If we use this, we get "used only once" warning.
  unless (*{$sym}{HASH}) {
    *$sym = {};
  }
  *{$sym}{HASH};
}

sub fields_array {
  my $sym = fields_symbol(@_);
  unless (*{$sym}{ARRAY}) {
    *$sym = [];
  }
  *{$sym}{ARRAY};
}

sub fields_symbol {
  globref($_[0], 'FIELDS');
}

sub isa_array {
  my $sym = globref($_[0], 'ISA');
  unless (*{$sym}{ARRAY}) {
    *$sym = [];
  }
  *{$sym}{ARRAY};
}

# sub define_const {
#   my ($name_or_glob, $value) = @_;
#   my $glob = ref $name_or_glob ? $name_or_glob : globref($name_or_glob);
#   *$glob = my $const_sub = sub () { $value };
#   $const_sub;
# }

# MOP4Import::Util::extract_fields_as(BASE_CLASS => $obj)
# => returns name, value pairs found in BASE_CLASS and defined in $obj.
# Note: this only extracts fields starting with [a-z].
sub extract_fields_as ($$) {
  my ($asPack, $obj) = @_;
  my $fields = fields_hash($asPack);
  map {
    if (/^[a-z]/ and defined $obj->{$_}) {
      ($_ => $obj->{$_})
    } else {
      ()
    }
  } keys %$fields
}

#
# Expand given item as list.
#
sub lexpand {
  if (not defined $_[0]) {
    return
  } elsif (ref $_[0] eq 'ARRAY') {
    @{$_[0]}
  } else {
    $_[0]
  }
}

sub terse_dump {
  join ", ", map {
    Data::Dumper->new([$_])->Terse(1)->Indent(0)->Dump;
  } @_;
}

#
# This may be useful to parse/take subcommand option/hash.
#
sub take_hash_opts_maybe {
  my ($pack, $list, $result) = @_;

  if (@$list and ref $list->[0] eq 'HASH') {
    # If first element of $list is HASH, take it.

    shift @$list;
  } else {
    # Otherwise, take --posix_style=options.

    $pack->parse_opts($list, $result);
  }
}

#
# posix_style long option.
#
sub parse_opts {
  my ($pack, $list, $result, $alias) = @_;
  my $wantarray = wantarray;
  unless (defined $result) {
    $result = $wantarray ? [] : {};
  }
  while (@$list and defined $list->[0] and my ($n, $v) = $list->[0]
	 =~ m{^--$ | ^(?:--? ([\w:\-\.]+) (?: =(.*))?)$}xs) {
    shift @$list;
    last unless defined $n;
    $n = $alias->{$n} if $alias and $alias->{$n};
    $v = 1 unless defined $v;
    if (ref $result eq 'HASH') {
      $result->{$n} = $v;
    } else {
      push @$result, $n, $v;
    }
  }
  $wantarray && ref $result ne 'HASH' ? @$result : $result;
}

#
# make style KEY=VALUE list
#
sub parse_pairlist {
  my ($pack, $aref, $do_box) = @_;
  my @res;
  while (@$aref and defined $aref->[0]
	 and $aref->[0] =~ /^([\w:\-\.]+)=(.*)/) {
    my $item = shift @$aref;
    push @res, $do_box ? [$1, $2] : ($1, $2);
  }
  @res;
}

sub function_names {
  my (%opts) = @_;
  my $packname = delete $opts{from}     // caller;
  my $pattern  = delete $opts{matching} || qr{^[A-Za-z]\w+$};
  my $except   = delete $opts{except}   // qr{^import$};
  if (keys %opts) {
    croak "Unknown arguments: ".join(", ", keys %opts);
  }
  my $symtab = *{globref($packname, '')}{HASH};
  my @result;
  foreach my $name (sort keys %$symtab) {
    next unless *{$symtab->{$name}}{CODE};
    next unless $name =~ $pattern;
    next if $except and $name =~ $except;
    push @result, $name;
  }
  @result;
}

our @EXPORT = qw/globref fields_hash fields_symbol lexpand terse_dump
		 fields_array
		/;
our @EXPORT_OK = function_names(from => __PACKAGE__
		   , except => qr/^(import|c\w*)$/
		 );

1;
