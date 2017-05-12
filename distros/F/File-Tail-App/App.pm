package File::Tail::App;

use strict;
use warnings;

use File::Tail;
use Carp ();

sub import {
    my $caller = caller();
    no strict 'refs';
    *{ $caller . '::tail_app' } = \&tail_app;
}

$File::Tail::App::VERSION = '0.4';

sub File::Tail::seek_to {
    my($tail, $seek_to) = @_;
    Carp::croak 'argument to seek_to() must be all digits' if $seek_to !~ m/^\d+$/;
    $tail->{'curpos'} = sysseek $tail->{'handle'}, $seek_to, 0;
}

sub File::Tail::app {
    my($tail, $args_ref) = @_;

    $args_ref->{'line_handler'} = sub { print shift; }
        if !$args_ref->{'line_handler'};
    Carp::croak '"line_handler" must be an code ref'
        if ref $args_ref->{'line_handler'} ne 'CODE';

    $args_ref->{'verbose'} = 0 if !defined $args_ref->{'verbose'};

    my $lastrun_file = $args_ref->{'lastrun_file'};
    my $do_md5_check = $args_ref->{'do_md5_check'} || 0;

    my($previous_position, $file_ident, $md5_chk, $md5_len) 
        = defined $lastrun_file ? _get_lastrun_data($tail->{'input'}, 
                                                    $lastrun_file,
                                                    $do_md5_check, 
                                                    $tail)
                                : ('','','','');

    $args_ref->{'seek_on_zero'} = 1 if !exists $args_ref->{'seek_on_zero'};
    if(exists $args_ref->{'seek_to'} && defined $args_ref->{'seek_to'}) {
        if($args_ref->{'seek_to'} eq '0' && $args_ref->{'seek_on_zero'}) {
            $tail->seek_to($args_ref->{'seek_to'});
        }
        elsif($args_ref->{'seek_to'} =~ m/^\d+$/) {
            $tail->seek_to($args_ref->{'seek_to'});
        }
    }

    my $start_size   = -s $tail->{'input'};
    my $start_handle = $tail->{'handle'}; 

    $tail->seek_to($previous_position) if $previous_position ne $start_size
                                          && $previous_position ne '';

    while( defined( my $line = $tail->read() ) ) {
        my @stat = stat $tail->{'input'};
        my $replaced = 0;
        if(-s $tail->{'input'} < $start_size) {
            Carp::carp "$tail->{'input'} was truncated: " . sysseek($tail->{'handle'},0,1)
                if $args_ref->{'verbose'};
            $tail->seek_to(length $line); 
            $replaced++;
        } 
        elsif($do_md5_check && $md5_chk ne _get_md5_info($tail, 
                                                       $md5_len, 
                                                       $do_md5_check)) {
            Carp::carp "MD5 Check changed: " . sysseek($tail->{'handle'},0,1)
                if $args_ref->{'verbose'};
            $replaced++;
        }

        if($replaced) {
            $tail->seek_to(length $line);
            $start_size = $stat[7];
            $md5_len = $stat[7] < 42  ? $stat[7] : 42;
            $md5_chk = _get_md5_info($tail, $md5_len, $do_md5_check);
        }

        # do simple checks then tell them about it & reset some vars if needed
        if($stat[1] ne $file_ident && $file_ident) {
            Carp::carp "$tail->{'input'} was replaced: " . sysseek($tail->{'handle'},0,1) 
                if $args_ref->{'verbose'};
            $file_ident = $stat[1];
        }
 
        if($start_handle ne $tail->{'handle'}) {
            # checking descriptor via fileno() is same check but numerically
            Carp::carp "descriptor/handle changed: " . sysseek($tail->{'handle'},0,1)
                if $args_ref->{'verbose'};
            $start_handle = $tail->{'handle'};
        }

        $args_ref->{'line_handler'}->($line);
        _set_lastrun_data( 
                           sysseek($tail->{'handle'},0,1),
                           $file_ident,
                           $md5_chk, 
                           $md5_len, 
                           $lastrun_file
                         ) if defined $lastrun_file;
        Carp::carp "$tail->{'input'} is at : " . sysseek($tail->{'handle'},0,1)
            if $args_ref->{'verbose'} > 1;
    }   
}

sub tail_app {
    my ($args_ref) = @_;

    Carp::croak 'tail_app() requires a hashref as its first argument' 
        if ref $args_ref ne 'HASH';

    Carp::croak 'missing "new" key from tail_app arg' if !exists $args_ref->{'new'};
    Carp::croak '"new" must be an array ref' if ref $args_ref->{'new'} ne 'ARRAY';

    my $tail = File::Tail->new(@{ $args_ref->{'new'} }) 
        or Carp::croak "Could not create File::Tail object: $!";

    $tail->app({
        'line_handler' => $args_ref->{'line_handler'},
        'verbose'      => $args_ref->{'verbose'},
        'seek_to'      => $args_ref->{'seek_to'},
        'seek_on_zero' => $args_ref->{'seek_on_zero'},
        'lastrun_file' => $args_ref->{'lastrun_file'}, 
        'do_md5_check' => $args_ref->{'do_md5_check'},
    });
}

sub _get_lastrun_data {
    my($tail_file, $cur_file, $do_md5_check, $tail) = @_;

    my @stat              = stat $tail_file;
    my $previous_position = 0; # start at zero if 1st time ...
    my $cur_tail_ident    = $stat[1]; #:$stat[10]# or if file's changed
    my $_md5_len          = $stat[7] < 42  ? $stat[7] : 42; 
    my $_md5_chk          = _get_md5_info($tail, $_md5_len, $do_md5_check);

    my($curpos, $logged_ident, $md5_chk, $md5_len) = ('','',$_md5_chk,$_md5_len);
    if(-e $cur_file) {
        open my $curat_fh, '<', $cur_file 
            or Carp::croak "Could not read $cur_file: $!";
        chomp(my $first_line = <$curat_fh>);
        close $curat_fh;

        ($curpos, $logged_ident, $md5_chk, $md5_len) = split /-/, $first_line;
        $curpos = 0 if $logged_ident ne $cur_tail_ident;
        $previous_position = int($curpos);
       
        if($do_md5_check) {
           $md5_len = $_md5_len if !defined $md5_len || !$md5_len; 
           $md5_chk = $_md5_chk if !defined $md5_chk || !$md5_chk;
        }
    }

    return ($previous_position, $cur_tail_ident, $md5_chk, $md5_len);
}

sub _set_lastrun_data {
    my($new_posi, $file_ident, $md5_chk, $md5_len, $cur_file) = @_;
    $md5_chk ||= 0;

    open my $curpos_fh, '>', $cur_file 
        or Carp::croak "Could not write $cur_file: $!";
    print {$curpos_fh} qq($new_posi-$file_ident-$md5_chk-$md5_len);
    close $curpos_fh;
}

sub _get_md5_info {
    my($tail, $md5_len, $do_md5_check) = @_;

    return if !$do_md5_check;
    require Digest::MD5; # only do the module if needed

    my $data_to_md5 = ''; # to avoid uninitialized value warnings
    my $origpos = sysseek($tail->{'handle'},0,1);

    $tail->seek_to(0);
    sysread $tail->{'handle'}, $data_to_md5, $md5_len;
    $tail->seek_to($origpos);

    return Digest::MD5::md5_hex($data_to_md5);
}

1;

__END__

=head1 NAME

File::Tail::App - Perl extension for making apps that tail files

=head1 SYNOPSIS

   use File::Tail::App;

   tail_app({
       'new'          => ['logfile.log'],
       'line_handler' => \&_wag_tail,
   });

   sub _wag_tail {
       my($line) = @_;
       # do what you want with the $line
   }

=head1 DESCRIPTION

Adds two methods for a File::Tail object and one function.

=head2 tail_app()

As in the SYNOPSIS, creates an app that processes a file's tail line by line.

Its only arg is a hashref with these keys:

=over 4

=item new

Required.
This is an array ref of the array you give to File::Tail's new method.

=item line_handler

This is a code ref that takes the current line in a string as its only argument. if you do not specify this the line is simply printed out.

=item seek_to

Before you start processing the file you can sysseek to this part of the file.

Like sysseek(), its value is in bytes. 

=item seek_on_zero

If this is false and seek_to is 0, then don't $tail->seek_to() it, 
Default is 1. 

=item lastrun_file

This is a file that is used to track the current position. It is recommended to use this so that if the program is terminated unexpectedly it can resume exactly where it left off so you will avoid duplicated or missing data.

If you'd rather do this your self the you'll need to get the current position before the call to app and send it via the seek_to key and log the new length at the end of your line processing function. You'll also need to be able to tell if the file you're tailing changes drastically because say you are currently at 12345 and the script is killed and then the log file is truncated before it is restarted. You don't want to start at 12345 in that case, you want to start at 0. 

The lastrun_file parameter handles all of that and more for you. Feel free to take a look at how it works if you need to write your own for some reason, like you want to use SQL DB instead of a file, etc etc...

=item do_md5_check

If using lastrun_file also do a check on the MD5 sum of a small part of data in the beginning of the file to see if its been truncated and handle appropriately. (Thanks to Ben Thomas for the MD5 idea!!)

=back

=head2 $tail->app()

Same args as tail_app except for the "new" key since you've already create the File::Tail object.

=head2 $tail->seek_to()

Given a digit, it will move to that position in the $tail object's handle. Useful for resuming where you left off.

Like sysseek(), its argument is in bytes.

=head2 EXPORT

None by default.

tail_app can be exported.

=head1 EXAMPLE

This example will process x.log as its updated. To avoid double logging it only allows one instance of itself to be run (See L<Unix::PID>). To avoid missing
 or double processing data if a problem arises it uses a lastrun file. So this is a pretty sturdy, reliable, and easy to code log processor:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Unix::PID '/var/run/xlogr.pid';
    use File::Tail::App qw(tail_app);

    tail_app({
        'new'          => ['x.log'],
        'line_handler' => \&_wag_tail,
        'lastrun_file' => 'x.lastrun',
    });

    sub _wag_tail {
        my($line) = @_;
        # do what you want with the $line
    }

=head1 BUGS

This was stress tested pretty vigorously for various circumstances so it should be pretty solid. If you do come across a problem please contact me with the code and steps neccessary to reproduce the bug so I can release a fix ASAP.

=head1 SEE ALSO

L<File::Tail>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
