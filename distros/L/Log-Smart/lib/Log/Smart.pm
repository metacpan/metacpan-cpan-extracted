package Log::Smart;

use warnings;
use strict;
our $VERSION = '0.009';

use 5.008;
use Carp;
use IO::File;
use base qw(Exporter);

our @EXPORT = qw(LOG YAML DUMP CLOSE);
my $arg_ref; # options
my $fhs_ref; # file handles


sub import {
    my $package = shift;
    my ($caller_package, $caller_name, $line) = caller(0);
    return 1 if $caller_name =~ m/\(eval\s.*\)/xms;
    my $TRUE = 1;
    my $FALSE = 0;
    my $file = $caller_name;
    my $arg;
    $file =~ m/(.*)\/.*\z/xms;
    $arg->{-path} = $1;
    $arg->{-name} = "$caller_package.log";
    $arg->{-timestamp} = $FALSE;

    my @symbols = ();
    push @_, @EXPORT;
    while (@_) {
        my $key = shift;
        if ($key =~ /^[-]/) {
            if ($key =~ /-path/) {
                $arg->{$key} = shift;
            }
            elsif ($key =~ /-name/) {
                $arg->{$key} = shift;
            }
            elsif ($key =~ /-timestamp/) {
                $arg->{$key} = $TRUE;
            }
            elsif ($key =~ /-append/) {
                $arg->{$key} = $TRUE;
            }
        }
        else {
            push @symbols, $key;
        }
    }

    $arg_ref->{$caller_package} = $arg;
    $fhs_ref->{$caller_package} = _open($arg);
    Exporter::export($package, $caller_package, @symbols);
}


sub _open {
    my $arg = shift;
    croak "[Log::Smart]permission denied.
      the output directory checks for write permission."
        unless -w "$arg->{-path}";

    # IO::File has insecure dependency problem.
    # Now, therefore not 'w' or '+<' but O_* mode. 
    my $mode = $arg->{-append} ? O_APPEND | O_CREAT : O_WRONLY | O_CREAT;
    my $fh = IO::File->new("$arg->{-path}/$arg->{-name}", $mode) or
        croak "IO::File can't open the file : "
        . $arg->{-path} . " name : " . $arg->{-name};
    return $fh;
}


sub LOG {
    my $value = shift;
    my $fh    = $fhs_ref->{ caller(0) };
    my $arg   = $arg_ref->{ caller(0) };

    _log($fh, $arg, $value);
    $fh->flush;
    return $value;
}

sub _log {
    my ($fh, $arg, $value) = @_;
    $value = '[' . localtime(time) . ']' . $value if $arg->{-timestamp};
    print $fh "$value\n" or croak "Can't print value.";
}

sub DUMP {
    my $fh    = $fhs_ref->{ caller(0) };
    my $arg   = $arg_ref->{ caller(0) };
    _dump($fh, $arg, @_);
    $fh->flush;
    return wantarray ? @_ : $_[0];
}

sub _dump {
    # Args must shifts because message or later is Dump args.
    my $fh      = shift;
    my $arg     = shift;
    my $message = shift;
    eval "require Data::Dumper";
    croak "Data::Dumper is not installed" if $@;
    $Data::Dumper::Sortkeys = 1;

    _log($fh, $arg, "[$message #DUMP]");
    print $fh Data::Dumper::Dumper(@_) or croak "Can't print value.";
}

sub YAML {
    my $message = shift;
    eval "require YAML";
    croak "YAML is not installed." if $@;

    my $fh    = $fhs_ref->{ caller(0) };
    my $arg   = $arg_ref->{ caller(0) };
    _log($fh, $arg, "[$message #YAML]");
    print $fh YAML::Dump(@_) or croak "Can't print value.";
    $fh->flush;
    return wantarray ? @_ : $_[0];
}

sub CLOSE {
    $fhs_ref->{ caller(0) }->close;
    delete $$fhs_ref{ caller(0) };
    delete $$arg_ref{ caller(0) };
}


=head1 NAME

Log::Smart - Messages for smart logging to the file 

=head1 VERSION

version 0.009

=cut

=head1 SYNOPSIS

    use Log::Smart -timestamp;
    
    LOG("write a message");
    DUMP("dump the data structures", $arg);
    YAML("dump the data structures back into yaml", $arg)

=head1 DESCRIPTION

B<Log::Smart> provides logging methods that is easy to use.

This module automatically creates and opens the file for logging.
It is created to location of the file that used this module.
And name of the file is the namespace + I<.log> with using this module.

It exports a function that you can put just about anywhere
in your Perl code to make it logging.

To change the location or filename, you can use the options.
Please refer to B<OPTIONS> for more information on.


    package Example;

    use Log::Smart;
    #file name "Example.log"


    package Example;
    
    use Log::Smart -name => 'mydebug.mylog';
    #file name "mydebug.mylog"

B<WARNING:>
This module automatically determines the output location(need write permission) and the filename when you don't use some options.
You should carefully use it, otherwise the file of same name is overwrited.

=head1 BACKWARD INCOMPATIBILITY

Current version of Log::Smart was once called Debug::Smart.
When I released this module naming it to Debug::Smart was wrong.
Debug::Smart was unmatched this module functions.
Thanks for nadim khemir of review.

=head1 EXPORT

=over

=item LOG

To write variable to the file.

=item DUMP

To write the variable structures to the file with Data::Dumper::Dumper.

=item YAML 

To write the variable structures to the file with YAML::Dump.

=item CLOSE

To close file handle if you want expressly.

=back

=head1 OPTIONS

    use Log::Smart -path => '/path/to/';

I<-path> option specify output location of the log file. 

    use Log::Smart -name => 'filename';

I<-filename> option specify the filename.

    use Log::Smart -timestamp;

I<-timestamp> option add timestamp to the head of logging message.

    use Log::Smart -append

I<-append> option is append mode. Writing at end-of-file.
Default is write mode. It will be overwritten.

=head1 AUTHOR

Kazuhiro Shibuya, C<< <k42uh1r0 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-debug-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Kazuhiro Shibuya, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Log::Smart
