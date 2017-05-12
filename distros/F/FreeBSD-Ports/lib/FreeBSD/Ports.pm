package FreeBSD::Ports;

use warnings;
use strict;

=head1 NAME

FreeBSD::Ports - A simple wrapper for working with the FreeBSD ports.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use FreeBSD::Ports;

    my $ports = FreeBSD::Ports->new();


=head1 METHODES

=head2 new

=cut

sub new{
	my %args;
	if (defined($_[1])) {
		%args= %{$_[1]};
	}

	#create the object that will be passed around
	my $self = {error=>undef, exitInt=>undef, errorString=>'',
				systemInt=>undef};
	bless $self;

	#figures out what to use for the ports dir
	if ($args{portsdir}) {
		$self->{portsdir}=$args{portsdir};
	}else {
		if(!defined($ENV{PORTSDIR})){
			$self->{portsdir}="/usr/ports/";
		}else{
			$self->{portsdir}=$ENV{PORTSDIR};
		}
	}

	return $self;
}

=head2 do

This runs a specified make type. Please see ports(7) for
more information on the available types.

Three arguements are accepted. The first is the type.
The second is the port. The third is a string containing
any options to be appended.

    $ports->do('install', 'www/firefox');
    if($ports->{error}){
        print "Errot!\n;";
    }

=cut

sub do{
	my $self=$_[0];
	my $type=$_[1];
	my $port=$_[2];
	my $options=$_[3];

	if (!defined($options)) {
		$options='';
	}

	my $sub='do';

	#make sure we cd to portsdir
	if (!chdir($self->{portsdir})) {
		my $error='The portsdir, "'.$self->portsdir.'", could not be CDed to';
		warn('FreeBSD-Ports '.$sub.':3: '.$error);
		$self->{error}=3;
		$self->{errorString}=$error;
		return undef;
	}

	#make sure we can cd to the port...
	#we do this after going to the portsdir as it is nice to be able to
	#differentiate between this and the previous
	if (!chdir($port)) {
		my $error='Could CD to the port, "'.$port.
		          '", from the portsdir, "'.$self->{portsdir}.'"';
		warn('FreeBSD-Ports '.$sub.':2: '.$error);
		$self->{error}=2;
		$self->{errorString}=$error;
		return undef;
	}

	system('make '.$type.' '.$options);
	#make sure it worked
	$self->{systemInt}=$?;
	$self->{exitInt}=$self->{systemInt} >> 8;
	if ($self->{systemInt} ne '0') {
		my $error='"make '.$type.' '.$options.'" errored with a return "'.$self->{systemInt}.'"';
		#we only add the returned int if it is not -1... other wise we get a big
		#meaningless number tacked on
		if ($self->{systemInt} ne '-1') {
			$error=$error.', "'.$self->{exitInt}.'"';
		}
		warn('FreeBSD-Ports do:4: '.$error);
		$self->{error}=4;
		$self->{errorString}=$error;
		return undef;
	}

	return 1;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}='';

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}='';

        return 1;
}

=head1 ERROR CODES

This is contained in $port->{error}. A description can be found in
$ports->{errorString}.

=head2 1

Command failed.

=head2 2

Port does not exist.

=head2 3

Portsdir does not exist.

=head2 4

Make errored.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-ports at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-Ports>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::Ports


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-Ports>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-Ports>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-Ports>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-Ports>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreeBSD::Ports
