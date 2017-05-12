package File::Basename::Object;

use 5.006;
use strict;
use warnings;
use overload
    '""'        =>  \&_as_string,
    'cmp'       =>  \&_compare,
    '<=>'        =>  \&_compare_basename,
    fallback    =>  1,
    ;

use File::Basename ();

our $VERSION = '0.01';

return 1;

sub new {
    my $class = shift;
    return bless [ @_ ], $class;
}

sub fullname {
    my($self, $path) = @_;
    my $old_path = $self->[0];
    $self->[0] = $path if(@_ > 1);
    return $old_path;
}

sub suffixlist {
    my($self, @suffixes) = @_;
    my @old_suffixes = @{$self}[$[ + 1 .. $#$self];
    splice(@$self, $[ + 1, $#$self, @suffixes) if(@_ > 1);
    return @old_suffixes;
}

sub no_suffixes {
    my $self = shift;
    return splice(@$self, 1);
}

sub copy {
    my $self = shift;
    my $rv = ref($self)->new(@$self);
    if(my $path = shift) {
        $rv->fullname($path);
    }
    return $rv;
}

sub _as_string {
    my $self = shift;
    return $self->[0];
}

sub fileparse {
    my $self = shift;
    return File::Basename::fileparse($self->fullname, $self->suffixlist);
}

sub basename {
    my $self = shift;
    return File::Basename::basename($self->fullname, $self->suffixlist);
}

sub dirname {
    my $self = shift;
    return File::Basename::dirname($self->fullname, $self->suffixlist);
}

sub _compare {
    my($a, $b) = @_;
    return "$a" cmp "$b";
}

sub _compare_basename {
    my($a, $b) = @_;
    if(UNIVERSAL::isa($b, __PACKAGE__)) {
        return scalar($a->fileparse) cmp scalar($b->fileparse);
    } else {
        return $a->_compare_basename(__PACKAGE__->new($b, @{$a}[ $[ + 1 .. $#$a ]));
    }
}


__END__

=pod

=head1 NAME

File::Basename::Object - Object-oriented syntax sugar for File::Basename

=head1 SYNOPSIS

  my $file = File::Basename::Object->new("/path/to/a/file.html", ".htm", ".html");
  
  if(open(my $fh, '<', $file)) {
    print "Now reading ", $file->basename, "\n";
    ...
  }

  if($file == "/another/path/to/file.htm") {
    print "$file shares it's base name with /another/path/to/file.htm\n";
  }

=head1 DESCRIPTION

C<File::Basename::Object> is an object-oriented wrapper around
L<File::Basename|File::Basename>. The goal is to allow pathnames to be
presented and manipulated easily.

A C<File::Basename::Object> stringifies to it's full canonical pathname,
so it can be used in open(), etc. without any trouble. When compared as
a string (C<cmp>, C<ne>, C<eq>, etc), it's full canonical pathname is
compared. When compared using numeric operators (C<==>, C<!=>, etc), the
file's base name is compared instead. Some methods are also provided:

=head1 CONSTRUCTOR

=over

=item File::Basename::Object->new($fullname, @suffixlist)

Creates a new C<File::Basename::Object>. C<$fullname> is the full pathname
you wish to store, and C<@suffixlist> is an option list of suffixes that you
are interested in removing from the file's name to obtain it's base.
Suffixes can be strings or regular expressions (C<qr{...}>);
see L<File::Basename> for more information.

=back

=head1 METHODS

=over

=item $object->fileparse

=item $object->basename

=item $object->dirname

These three methods execute their counterparts in
L<File::Basename|File::Basename> with the same arguments as were given in
the object's constructor.

=item $object->fullname($newname)

Get and/or set the full pathname. If C<$newname> is specified, that is
taken as the new pathname. The old pathname is returned.

=item $object->suffixlist(@suffixes)

Get and/or set the list of suffixes we wish to strip from the file's
base name. If C<@suffixes> is specified, that is taken as the new list
of suffixes. The old list of suffixes is returned.

=item $object->no_suffixes

Clear the list of suffixes, so that no suffixes are stripped from the
file's base name. The old list of suffixes is returned.

=item $object->copy($newname)

Return a clone of this object. If C<$newname> is specified, that is used as
the fullname for the new object.

=back

=head1 SEE ALSO

L<File::Basename>

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

=head1 LICENSE

Copyright 2006 Tyler MacDonald.

This is free software; you may redistribute it under the same terms as perl itself.

=cut
