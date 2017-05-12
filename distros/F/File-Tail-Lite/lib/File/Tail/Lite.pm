package File::Tail::Lite;
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my $pkg  = shift;
    my $self = {@_};
    bless $self, $pkg;

    unless ( defined $self->{filename} and -e $self->{filename} ) {
        $self->{error}   = 1;
        $self->{errinfo} = "error input filename";
        return $self;
    }

    unless ( open $self->{fh}, "<", $self->{filename} ) {
        $self->{error}   = 1;
        $self->{errinfo} = "error open file";
        return $self;
    }

    my $seek_position;
    my $seek_whence;    # 0:begin, 1:current, 2:eof
    if ( !defined $self->{seekpos} ) {
        $seek_position = 0;
        $seek_whence   = 2;
    }
    else {
        if (   $self->{seekpos} eq 'begin'
            or $self->{seekpos} eq 'new'
            or $self->{seekpos} eq 'start' )
        {
            $seek_position = 0;
            $seek_whence   = 0;
        }
        elsif ( $self->{seekpos} eq 'end' or $self->{seekpos} eq 'eof' ) {
            $seek_position = 0;
            $seek_whence   = 2;
        }
        elsif ( $self->{seekpos} =~ /^[0-9]+$/ ) {
            $seek_position = $self->{seekpos};
            $seek_whence   = 0;
        }
        else {
            $self->{error}   = 1;
            $self->{errinfo} = "error seekpos";
            return $self;
        }
    }
    unless ( sysseek( $self->{fh}, $seek_position, $seek_whence ) ) {
        $self->{error}   = 1;
        $self->{errinfo} = "error seek file";
        return $self;
    }

    $self->{maxbuf} = 1024
      if !$self->{maxbuf}
      or int( $self->{maxbuf} ) < 1
      or int( $self->{maxbuf} ) > 1024 * 1024;

    return $self;
}

sub readline {
    my $self = shift;
    if ( $self->{error} ) {
        return $self->{errinfo};
    }

    my $line;
    while (1) {
        my $buf;
        my $ret = sysread( $self->{fh}, $buf, 1 );
        if ($ret) {
            $line .= $buf;
            if ( $buf =~ /[\r\n]/ or length($line) >= $self->{maxbuf} ) {
                return ( sysseek( $self->{fh}, 0, 1 ), $line );
            }
        }
        else {
            sleep 1;
        }
    }
}

1;

__END__

=head1 NAME

File::Tail::Lite - Perl module for seekable 'tailf' implementation

=head1 SYNOPSIS

Simple usage.

  use File::Tail::Lite;
  my $tailf = new File::Tail::Lite(filename => "/some_path/filename_for_tailf");
  while(my $line) = $tailf->readline())
  {
    print $line;
  }

Get position everytime, so we will not miss any content when crash happens.

  use File::Tail::Lite;
  my $tailf = new File::Tail::Lite(filename => "/some_path/filename_for_tailf");
  while(my ($pos, $line) = $tailf->readline())
  {
    print "[$pos,$line]";
  }

Seek to a position when start reading.

  use File::Tail::Lite;
  my $seekpos = sub_recover_pos();

  my $tailf = new File::Tail::Lite(filename => "/some_path/filename_for_tailf", seekpos => $seekpos);
  while(my ($pos, $line) = $tailf->readline())
  {
    print "[$pos,$line]";
    $seekpos = $pos;
    sub_save_pos($seekpos);
  }

Note that the above scripts will never exit. If there is nothing being written to the file, it will simply block.


=head1 DESCRIPTION

This module is made for seekable 'tailf' implementation.

L<File::Tail> is good, but it can not seek when reading started,so we may miss contents if programe crash.

This module slove the problem.

And it is quite simple and easy to use.


=head1 METHOD

=head2 $file_tail_lite->readline()

return one line one time, blocks until that.

also return $self->{maxbuff} bytes if the line is too long to handle.

=head2 $file_tail_lite->{error}

0 : no error.

1 : error happened.

=head2 $file_tail_lite->{errinfo}

A string desc the error.

This will be set when $self->{error} == 1.


=head1 CONSTRUCTOR

=head2 new ([ ARGS])

=over

=item filename

The name of the file want to tailf.

=item seekpos

default: 'eof'. 

int     - start reading from the specified offset

'begin' - read from the head of the file.

'eof'   - read the new append contents only.

=item maxbuf

default: 1024. 

readline() returns a line by default.

set the max line length here, so that readline() can break long line.

=back

=head1 EXAMPLE

  use File::Tail::Lite;
  use Storable qw(retrieve store);

  my $stor_file = '/tmp/seekpos.tmp';
  my $seekpos = retrieve($stor_file) || 'end';

  my $tailf = new File::Tail::Lite(filename => "/var/log/httpd/access.log", seekpos => $seekpos, maxbuf => 100);
  while(my ($pos, $line) = $tailf->readline())
  {
    print "[$pos,$line]";
    store \$pos, $stor_file;
  }
             
=head1 AUTHOR

Written by Chen Gang

yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2014 Chen Gang.

This library is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<File::Tail>
