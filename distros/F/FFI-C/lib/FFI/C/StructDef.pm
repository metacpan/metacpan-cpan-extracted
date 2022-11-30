package FFI::C::StructDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Util;
use FFI::C::Struct;
use FFI::C::FFI ();
use FFI::Platypus 1.24;
use Ref::Util qw( is_blessed_ref is_plain_arrayref is_ref );
use Carp ();
use Sub::Install ();
use Sub::Util ();
use Scalar::Util qw( refaddr );
use constant _is_union => 0;
use base qw( FFI::C::Def );

our @CARP_NOT = qw( FFI::C::Util FFI::C );

# ABSTRACT: Structured data definition for FFI
our $VERSION = '0.15'; # VERSION


sub _is_kind
{
  my($self, $name, $want) = @_;
  my $kind = eval { $self->ffi->kindof($name) };
  return undef unless defined $kind;
  return $kind eq $want;
}

sub new
{
  my $self = shift->SUPER::new(@_);

  my %args = %{ delete $self->{args} };

  $self->{trim_string} = delete $args{trim_string} ? 1 : 0;
  my $offset    = 0;
  my $alignment = 0;
  my $anon      = 0;

  if(my @members = @{ delete $args{members} || [] })
  {
    Carp::croak("Odd number of arguments in member spec") if scalar(@members) % 2;
    while(@members)
    {
      my $name = shift @members;
      my $spec = shift @members;
      my %member;

      if($name ne ':' && $self->{members}->{$name})
      {
        Carp::croak("More than one member with the name $name");
      }

      if($name eq ':')
      {
        $name .= (++$anon);
      }
      elsif($name !~ /^[A-Za-z_][A-Za-z_0-9]*$/)
      {
        Carp::croak("Illegal member name");
      }
      elsif($name eq 'new')
      {
        Carp::croak("new now allowed as a member name");
      }

      if(my $def = $self->ffi->def('FFI::C::Def', $spec))
      {
        $spec = $def;
      }
      elsif($def = $self->ffi->def('FFI::C::EnumDef', $spec))
      {
        $spec = $def;
      }

      if(is_blessed_ref $spec)
      {
        if($spec->isa('FFI::C::Def'))
        {
          Carp::croak("Canot nest a struct or union def inside of itself")
            if refaddr($spec) == refaddr($self);
          $member{nest}  = $spec;
          $member{size}  = $spec->size;
          $member{align} = $spec->align;
        }
        elsif($spec->isa('FFI::C::EnumDef'))
        {
          $member{spec}       = $spec->type;
          $member{size}       = $self->ffi->sizeof($spec->type);
          $member{align}      = $self->ffi->alignof($spec->type);
          $member{enum}       = $spec;
        }
      }
      elsif($self->_is_kind($spec, 'scalar'))
      {
        $member{spec}   = $spec;
        $member{size}   = $self->ffi->sizeof($spec);
        $member{align}  = $self->ffi->alignof($spec);
      }
      elsif($self->_is_kind($spec, 'array'))
      {
        $member{spec}     = $self->ffi->unitof($spec);
        $member{count}    = $self->ffi->countof($spec);
        $member{size}     = $self->ffi->sizeof($spec);
        $member{unitsize} = $self->ffi->sizeof($member{spec});
        $member{align}    = $self->ffi->alignof($spec);
        Carp::croak("array members must have at least one element")
          unless $member{count} > 0;
      }
      elsif($self->_is_kind("$spec*", 'record'))
      {
        local $@;
        $member{align}       = eval { $self->ffi->alignof("$spec*") };
        $member{trim_string} = 1 if $self->{trim_string};
        $member{spec}        = $spec;
        $member{rec}         = 1;
        $member{size}        = $self->ffi->sizeof("$spec*");
        Carp::croak("undefined, or unsupported type: $spec") if $@;
      }
      else
      {
        Carp::croak("undefined or unsupported type: $spec");
      }

      $self->{align} = $member{align} if $member{align} > $self->{align};

      if($self->_is_union)
      {
        $self->{size} = $member{size} if $member{size} > $self->{size};
        $member{offset} = 0;
      }
      else
      {
        $offset++ while $offset % $member{align};
        $member{offset} = $offset;
        $offset += $member{size};
      }

      $self->{members}->{$name} = \%member;
    }
  }

  $self->{size}        = $offset unless $self->_is_union;

  Carp::carp("Unknown argument: $_") for sort keys %args;

  if($self->class)
  {
    # not handled by the superclass:
    #  3. Any nested cdefs must have Perl classes.

    foreach my $name (keys %{ $self->{members} })
    {
      next if $name =~ /^:/;
      my $member = $self->{members}->{$name};
      my $accessor = $self->class . '::' . $name;
      Carp::croak("Missing Perl class for $accessor")
        if $member->{nest} && !$member->{nest}->{class};
    }

    $self->_generate_class(keys %{ $self->{members} });

    {
      my $ffi = $self->ffi;

      foreach my $name (keys %{ $self->{members} })
      {
        my $offset = $self->{members}->{$name}->{offset};
        my $code;
        if($self->{members}->{$name}->{nest})
        {
          my $class = $self->{members}->{$name}->{nest}->{class};
          $code = sub {
            my $self = shift;
            my $ptr = $self->{ptr} + $offset;
            my $m = $class->new($ptr,$self);
            FFI::C::Util::perl_to_c($m, $_[0]) if @_;
            $m;
          };
        }
        else
        {
          my $type  = $self->{members}->{$name}->{spec} . '*';
          my $size  = $self->{members}->{$name}->{size};

          my $set = $ffi->function( FFI::C::FFI::memcpy_addr() => ['opaque',$type,'size_t'] => $type)->sub_ref;
          my $get = $ffi->function( 0                          => ['opaque'] => $type)->sub_ref;

          if($self->{members}->{$name}->{rec})
          {
            if($self->{trim_string})
            {
              unless(__PACKAGE__->can('_cast_string'))
              {
                $ffi->attach_cast('_cast_string', 'opaque', 'string');
              }
              $set = $ffi->function( FFI::C::FFI::memcpy_addr() => ['opaque',$type,'size_t'] => 'string')->sub_ref;
              $get = \&_cast_string;
            }
            $code = sub {
              my $self = shift;
              my $ptr = $self->{ptr} + $offset;
              if(@_)
              {
                my $length = do { use bytes; length $_[0] };
                my $src = \($size > $length ? $_[0] . ("\0" x ($size-$length)) : $_[0]);
                return $set->($ptr, $src, $size);
              }
              $get->($ptr)
            };
          }
          elsif(my $count = $self->{members}->{$name}->{count})
          {
            my $unitsize = $self->{members}->{$name}->{unitsize};
            my $atype    = $self->{members}->{$name}->{spec} . "[$count]";
            my $all = $ffi->function( FFI::C::FFI::memcpy_addr() => ['opaque',$atype,'size_t'] => 'void' );
            $code = sub {
              my $self = shift;
              if(defined $_[0])
              {
                if(is_plain_arrayref $_[0])
                {
                  my $array = shift;
                  Carp::croak("$name OOB index on array member") if @$array > $count;
                  my $ptr = $self->{ptr} + $offset;
                  my $size = (@$array ) * $unitsize;
                  $all->($ptr, $array, (@$array * $unitsize));
                  # we don't want to have to get the array and tie it if
                  # it isn't going to be used anyway.
                  return unless defined wantarray;  ## no critic (Community::Wantarray)
                }
                elsif(! is_ref $_[0])
                {
                  my $index = shift;
                  Carp::croak("$name Negative index on array member") if $index < 0;
                  Carp::croak("$name OOB index on array member") if $index >= $count;
                  my $ptr = $self->{ptr} + $offset + $index * $unitsize;
                  return @_
                    ? ${ $set->($ptr,\$_[0],$unitsize) }
                    : ${ $get->($ptr) };
                }
                else
                {
                  Carp::croak("$name tried to set element to non-scalar");
                }
              }
              my @a;
              tie @a, 'FFI::C::Struct::MemberArrayTie', $self, $name, $count;
              return \@a;
            };
          }
          elsif(my $enum = $self->{members}->{$name}->{enum})
          {
            my $str_lookup = $enum->str_lookup;
            my $int_lookup = $enum->int_lookup;
            if($enum->rev eq 'str')
            {
              $code = sub {
                my $self = shift;
                my $ptr = $self->{ptr} + $offset;
                Carp::croak("$name tried to set member to non-scalar") if @_ && is_ref $_[0];
                my $ret = @_
                  ? do {
                    my $arg = exists $str_lookup->{$_[0]}
                      ? $str_lookup->{$_[0]}
                      : exists $int_lookup->{$_[0]}
                        ? $_[0]
                        : Carp::croak("No such value for $name: $_[0]");
                    ${ $set->($ptr,\$arg,$size) }
                  }
                  : ${ $get->($ptr) };
                $int_lookup->{$ret}
                  ? $int_lookup->{$ret}
                  : $ret;
              };
            }
            else
            {
              $code = sub {
                my $self = shift;
                my $ptr = $self->{ptr} + $offset;
                Carp::croak("$name tried to set member to non-scalar") if @_ && is_ref $_[0];
                @_
                  ? do {
                    my $arg = exists $str_lookup->{$_[0]}
                      ? $str_lookup->{$_[0]}
                      : exists $int_lookup->{$_[0]}
                        ? $_[0]
                        : Carp::croak("No such value for $name: $_[0]");
                    ${ $set->($ptr,\$arg,$size) }
                  }
                  : ${ $get->($ptr) };
              };
            }
          }
          else
          {
            $code = sub {
              my $self = shift;
              my $ptr = $self->{ptr} + $offset;
              Carp::croak("$name tried to set member to non-scalar") if @_ && is_ref $_[0];
              @_
                ? ${ $set->($ptr,\$_[0],$size) }
                : ${ $get->($ptr) };
            };
          }
        }

        Sub::Util::set_subname(join('::', $self->class, $name), $code);
        Sub::Install::install_sub({
          code => $code,
          into => $self->class,
          as   => $name,
        });
      }
    }
  }

  $self;
}


sub trim_string { shift->{trim_string} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::StructDef - Structured data definition for FFI

=head1 VERSION

version 0.15

=head1 SYNOPSIS

In your C code:

 #include <stdint.h>
 #include <stdio.h>
 
 typedef struct {
   uint8_t red;
   uint8_t green;
   uint8_t blue;
 } color_t;
 
 void
 print_color(color_t *c)
 {
   printf("[%02x %02x %02x]\n",
     c->red,
     c->green,
     c->blue
   );
 }

In your Perl code:

 use FFI::Platypus 1.00;
 use FFI::C::StructDef;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 # See FFI::Platypus::Bundle for how bundle works.
 $ffi->bundle;
 
 my $def = FFI::C::StructDef->new(
   $ffi,
   name  => 'color_t',
   class => 'Color',
   members => [
     red   => 'uint8',
     green => 'uint8',
     blue  => 'uint8',
   ],
 );
 
 my $red = Color->new({ red => 255 });
 
 my $green = Color->new({ green => 255 });
 
 $ffi->attach( print_color => ['color_t'] );
 
 print_color($red);   # [ff 00 00]
 print_color($green); # [00 ff 00]
 
 # that red is a tad bright!
 $red->red( 200 );
 
 print_color($red);   # [c8 00 00]

=head1 DESCRIPTION

This class creates a def for a C C<struct>.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::StructDef->new(%opts);
 my $def = FFI::C::StructDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference containing name, type pairs,
in the order that they will be stored in the struct.

=item trim_string

If true, fixed-length strings should be treated as null terminated
strings and be trimmed.

=back

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create(\%init);
 my $instance = $def->class->new(\%init);  # if class was specified

This creates an instance of the C<struct>, returns a L<FFI::C::Struct>.

You can optionally initialize member values using C<%init>.

=head2 trim_string

 my $bool = $def->trim_string;

Returns true if fixed-length strings should be treated as null terminated
strings and be trimmed.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
