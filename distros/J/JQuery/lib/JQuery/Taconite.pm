package JQuery::Taconite;

our $VERSION = '1.00';

use warnings;
use strict;

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
#    die "No id defined for Taconite" unless $my->{param}{id} =~ /\S/ ; 
#    die "No remote program defined for Taconite" unless $my->{param}{remoteProgram} =~ /\S/ ; 

    bless $my, $class;

    if ($my->{param}{css}) { 
	push @{$my->{css}},$my->{param}{css} ; 
    } 

    $my->{param}{debug} = 0 unless defined $my->{param}{debug} ; 
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
    return ('taconite/jquery.taconite.js') ; 
} 


sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 
    return '' unless $id =~ /\S/ ; 
    my $runMode = '' ; 
    if (defined $my->{param}{rm}) { 
	$runMode = qq[rm: "$my->{param}{rm}", ] ; 
    }
    
    my $function =<<'EOD';
DEBUG
$('#ID').click(function() { 
    $.post("PROGRAM_TO_RUN", { RUNMODE ts: new Date().getTime()} ); 
    });
EOD
    if ( $my->{param}{debug} ) { 
	$function =~ s!DEBUG!$.taconite.debug = true;! ;
    } else { 
	$function =~ s!DEBUG!! ;
    } 
    $function =~ s/ID/$id/ ; 
    $function =~ s/PROGRAM_TO_RUN/$remoteProgram/ ; 
    $function =~ s/RUNMODE/$runMode/ ; 
    return $function ; 
}
1;

=head1 NAME

JQuery::Taconite - an Ajax interface

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

Taconite installs the taconite javascript and doesn't do much else

    use JQuery;
    use JQuery::Taconite;

    $jquery = new JQuery(...) ; 
    JQuery::Taconite->new(addToJQuery => $jquery) ; 
    JQuery::Form->new(id => 'myForm', addToJQuery => $jquery) ; 


If used without a form:

    $jquery = new JQuery(...) ; 
    JQuery::Taconite->new(id => 'ex6', remoteProgram => '/cgi-bin/program_to_run.pl', rm => 'reply', addToJQuery => $jquery); 


=head1 FUNCTIONS

=over

=item new

Instantiate the object

=item debug 

Set to 1 to enable debugging. You can see the results in Firebug.

=back

=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jquery-taconite at rt.cpan.org>, or through the web interface at
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

1; # End of JQuery::Taconite
