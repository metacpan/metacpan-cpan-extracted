package JQuery::Heartbeat;

our $VERSION = '1.00';

use warnings;
use strict;

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
#    die "No id defined for Taconite" unless $my->{param}{id} =~ /\S/ ; 
    die "No remote program defined for Heartbeat" unless $my->{param}{remoteProgram} =~ /\S/ ; 
    $my->{param}{rm} = '' unless defined $my->{param}{rm} ; 
    $my->{param}{delay} = '5000' unless defined $my->{param}{delay} ; 
    bless $my, $class;

    if ($my->{param}{css}) { 
	push @{$my->{css}},$my->{param}{css} ; 
    } 

    $my->add_to_jquery ; 
    return $my ;
}

sub add_to_jquery { 
    my $my = shift ; 
    my $jquery = $my->{param}{addToJQuery} ; 
    if (defined $jquery) { 
	$jquery->add($my) ; 
    } 
} 

sub id {
    my $my = shift ;
    return $my->{param}{id} ; 
}


sub packages_needed { 
    my $my = shift ;
    return ('taconite/jquery.taconite.js','heartbeat/heartbeat.js') ; 
} 


sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 

    my $runMode = $my->{param}{rm} ; 
    my $function =<<'EOD';
	$.jheartbeat.set({
		url: "PROGRAM_TO_RUNRUNMODE",
		DELAY
	});
EOD
    $function =~ s!PROGRAM_TO_RUN!$remoteProgram! ; 
    if ($runMode =~/\S/) { 
	$function =~ s/RUNMODE/?rm=$runMode/ ; 
    } else { 
	$function =~ s/RUNMODE// ; 
   }
    if ($my->{param}{delay} =~ /\S/) { 
	$function =~ s!DELAY!delay: $my->{param}{delay}! ; 
    } else { 
	$function =~ s!DELAY!! ; 
    } 
    return $function ; 
}
1;

=head1 NAME

JQuery::Heartbeat - an interface to JHeartbeat

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

JHeartbeat installs the heartbeat javascript and calls the specified url on each timeout

    use JQuery;
    use JQuery::Heartbeat;

    $jquery = new JQuery(...) ; 
    JQuery::Heartbeat->new(addToJQuery => $jquery, remoteProgram => 'jquery_heartbeat_results.pl', rm => 'heartbeatRunMode', delay => 1000) ; 
    
    To force the various browsers into non-cache mode, a variable, counter, is automatically added to the end of the url. 

=head1 FUNCTIONS

=over

=item new

=back 

Instantiate the object

=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jquery at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JQuery>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JQuery

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JQuery>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/JQuery>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Gordon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of JQuery::Heartbeat
