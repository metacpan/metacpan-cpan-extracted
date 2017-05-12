package JQuery::Form ; 

our $VERSION = '1.00';

use warnings;
use strict;


sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
    die "No id defined for Form" unless $my->{param}{id} =~ /\S/ ; 

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
    return ('taconite/jquery.taconite.js','form/jquery.form.js') ; 
} 


sub get_jquery_code { 
    my $my = shift ; 
    my $id = $my->id ; 
    my $remoteProgram = $my->{param}{remoteProgram} ; 

    my $function =<<'EOD';
$('#ID').ajaxForm(function() { 
}); 
EOD
    $function =~ s/ID/$id/ ; 
    return $function ; 
}
1;

__END__

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

    return $my ;
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
    my $function =<<'EOD';
$('#ID').click(function() { 
    $.post('PROGRAM_TO_RUN?ts='+new Date().getTime(), {}); 
    });
EOD

    $function =~ s/ID/$id/ ; 
    $function =~ s/PROGRAM_TO_RUN/$remoteProgram/ ; 
    return $function ; 
}

=head1 NAME

JQuery::Form - Send form information

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use JQuery::Form ; 

    # define JQuery
    my $jquery = new JQuery(...)
    $jquery->add(JQuery::Form->new(id => 'myForm')) ; 

Create a form, add the form id to JQuery, and when requested, send the reply.

=head1 DESCRIPTION

=head2 Main Page

    use JQuery ; 
    use JQuery::Form ; 

    # define JQuery
    my $jquery = new JQuery(...)
    JQuery::Form->new(id => 'myForm', addToJQuery => $jquery) ; 

    my $html =<<EOD; 
    <form id="myForm" action="/cgi-bin/jquery_form.pl" method="post"> 
      Name: <input type="text" name="name" /><br/> 
      Comment: <textarea name="comment"></textarea><br/> 
      <input type="submit" value="Submit Comment" /><br/> 
      <input type=hidden name="rm" value="reply" /><br/>
    </form>
    <div id="example4" style="background-color: orange; padding:10px; border:1px solid #bbb"> </div>	 

    my $result=<<EOD;

=head2 Reply Page
   
Construct the reply. See L<http://www.malsup.com/jquery/taconite/> for
all the options. With this, you can change content, add and remove
items and more.

   $result=<<EOD;
   <taconite> 
    <after select="#example1"> 
           This text will go after the example div. 
    </after>  
   </taconite>
   EOD
   my $q = new CGI ; 
   print $q->header(-type=>'text/xml');
   print $result ;


When sending the reply, ensure that the header is of type text/xml,
ensure all tags are XML, which means that all tags must be terminated,
and lastly, ensure that nothing else is sent. 

=head1 FUNCTIONS

=over 

=item new

Instantiate the object

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

1; # End of JQuery::Form


