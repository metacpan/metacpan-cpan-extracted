package File::Find::Rule::Filesys::Virtual;
use strict;
use warnings;
use File::Find::Rule 0.28;
use base qw( File::Find::Rule );
our $VERSION = 1.22;

=head1 NAME

File::Find::Rule::Filesys::Virtual - File::Find::Rule adapted to Filesys::Virtual

=head1 SYNOPSIS

 use File::Find::Rule::Filesys::Virtual;
 use Filesys::Virtual::Ninja;
 my $vfs = Filesys::Virtual::Ninja->new;
 my @virtual_ninja_foos = File::Find::Rule::Filesys::Virtual
   ->virtual( $vfs )
   ->name( "foo.*' )
   ->in( '/' );

=head1 DESCRIPTION

This module allows you to use File::Find::Rule file finding semantics
to Filesys::Virtual derived filesystems.

=cut


BEGIN { *_force_object = \&File::Find::Rule::_force_object }
sub virtual {
    my $self = _force_object shift;
    $self->{_virtual} = shift;
    return $self;
}

our %X_tests;
*X_tests = \%File::Find::Rule::X_tests;
for my $test (keys %X_tests) {
    $test =~ s/^-//;
    my $sub = eval 'sub () {
        my $self = _force_object shift;
        push @{ $self->{rules} }, {
           code => "\$File::Find::vfs->test(q{' . $test . '}, \$_)",
           rule => "'.$X_tests{"-$test"}.'",
        };
        return $self;
    } ';
    no strict 'refs';
    *{ $X_tests{"-$test"} } = $sub;
}

{
    our @stat_tests;
    *stat_tests = \@File::Find::Rule::stat_tests;

    my $i = 0;
    for my $test (@stat_tests) {
        my $index = $i++; # to close over
        my $sub = sub {
            my $self = _force_object shift;

            my @tests = map { Number::Compare->parse_to_perl($_) } @_;

            push @{ $self->{rules} }, {
                rule => $test,
                args => \@_,
                code => 'do { my $val = ($File::Find::vfs->stat($_))['.$index.'] || 0;'.
                  join ('||', map { "(\$val $_)" } @tests ).' }',
            };
            return $self;
        };
        no strict 'refs';
        *$test = $sub;
    }
}

sub grep {
    my $self = _force_object shift;
    my @pattern = map {
        ref $_
          ? ref $_ eq 'ARRAY'
            ? map { [ ( ref $_ ? $_ : qr/$_/ ) => 0 ] } @$_
            : [ $_ => 1 ]
          : [ qr/$_/ => 1 ]
      } @_;

    $self->exec( sub {
        my $vfs = $File::Find::vfs;
        my $fh = $vfs->open_read($_) or return;
        local ($_, $.);
        while (<$fh>) {
            for my $p (@pattern) {
                my ($rule, $ret) = @$p;
                if (ref $rule eq 'Regexp' ? /$rule/ : $rule->(@_)) {
                  $vfs->close_read($fh);
                  return $ret;
                }
            }
        }
        $vfs->close_read($fh);
        return;
    } );
}


sub _call_find {
    my $self = shift;
    my %args = %{ shift() };
    my $path = shift;
    my $vfs = local $File::Find::vfs = $self->{_virtual};
    my $cwd = $vfs->cwd;
    __inner_find( $args{wanted}, $path, "" );
    $vfs->chdir( $cwd );
}

# fake the behaviour of File::Find.  It burns!
sub __inner_find {
    my $wanted = shift;
    my $path   = shift;
    my $parent = shift;
    my $vfs = $File::Find::vfs;

    unless ( $vfs->chdir( $path ) ) {
        # Couldn't chdir into it, so we see if it's a file.
        # Actually because there are many forms of "file" (plain,
        # symlink, socket, block, character) we just check if it
        # exists and that it's not a directory.
        if ($vfs->test('e', $path) && !$vfs->test('d', $path)) {
            my ($dir, $name) = $path =~ m{^(.*/)(.*)};
            local $_ = $name;
            local $File::Find::dir  = $dir;
            local $File::Find::name = $path;
            local $File::Find::prune;
            $vfs->chdir($dir);
            $wanted->();
        }
        return; # I have no clue - bail
    }
    local $File::Find::dir  = $parent ? "$parent/$path" : $path;
    for my $name ($vfs->list) {
        local $_ = $name;
        local $File::Find::name = "$File::Find::dir/$name";
        local $File::Find::prune;
        #print "_:    $_\n";
        #print "dir:  $File::Find::dir\n";
        #print "name: $File::Find::name\n";

        $wanted->();

        if ($vfs->test("d", $name ) && !$File::Find::prune && $name !~ /^\..?$/) {
            my $cwd = $vfs->cwd;
            __inner_find( $wanted, $name, $File::Find::dir );
            $vfs->chdir( $cwd );
        }
    }
}


1;

__END__

=head1 CAVEATS

=over

=item

The File::Find emulation will probably not be full enough for other
File::Find::Rule extensions to do their thang.

=back

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, 2006 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Filesys::Virtual>, L<Net::DAV::Server>

=cut
