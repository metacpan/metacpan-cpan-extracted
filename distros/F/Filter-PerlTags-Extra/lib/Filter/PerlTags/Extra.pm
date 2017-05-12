package Filter::PerlTags::Extra;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Filter::PerlTags::Extra - More mixed Perl/HTML, with some CGI built-in

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use Filter::PerlTags::Extra;
    <html>
    <body>
    <form method="post">
    <select name="mysel">
    <? foreach (0..9){ ?>
        <option value="$_" <? $_ eq $Q{mysel} && ?> selected="selected"
        ><? print chr(65+$_); ?></option>
    <? }  ?>
    </select>
    </form>
    You've been on this page 
<? $SESSION{count}++ ; ?> $SESSION{count} times today!
    </body>
    </html>

The module sends a session cookie in the header.  That is all.  If you want more,
you'll probably need to look elsewhere, or ask me for features.

ALL the additions to the code are done per line and do not break lines,
so if your script breaks, and you'll see the errors because of fatalsToBrowser,
the line numbers you see should correspond EXACTLY with those in your source.


=head1 EXPORT

This is a filter, so it doesn't exactly export things, but you will end up with 
some variables in your space:

    %SESSION
    
A session cookie is sent to the browser and any modifications you make to
%SESSION are stored and reloaded next time the user visits (temporary though)

    %Q

As got by CGI->Vars.  This contains the data from GET, POST, etc.

Also, the filter adds the following to the start of your code:

    use CGI qw/:standard :cgi-lib/; 
    use CGI::Carp qw(fatalsToBrowser); 
    use CGI::Cookie; 
    use MIME::Base64; 
    use Data::Dumper; 
    use Time::HiRes qw/time/; 

So all the exports from that are in your space too, lucky you!

The results of 

    CGI::Cookie->fetch;
    
are stored in

    %COOKIES

=head1 AUTHOR

Jimi Wills, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-filter-perltags-extra at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-PerlTags-Extra>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Filter::PerlTags::Extra


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Filter-PerlTags-Extra>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Filter-PerlTags-Extra>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Filter-PerlTags-Extra>

=item * Search CPAN

L<http://search.cpan.org/dist/Filter-PerlTags-Extra/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jimi Wills.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

use Filter::Util::Call;

our $begin = q`use CGI qw/:standard :cgi-lib/; use CGI::Carp qw(fatalsToBrowser); use CGI::Cookie; use MIME::Base64; use Data::Dumper; use Time::HiRes qw/time/; sub sessionID {	foreach(encode_base64( pack "F*", time, rand, rand, rand, rand )){ tr!=+/!_.-!;	return $_; }} our %COOKIES = CGI::Cookie->fetch; $SESSION::ID = $COOKIES{'sid'} ? $COOKIES{'sid'}->value : sessionID(); $SESSION::PATH = $CGITempFile::TMPDIRECTORY.'/session.'; our %SESSION = (); my $fn = $SESSION::PATH . $SESSION::ID; if( -e $fn ){ open(my $fh, '<', $fn) or carp "Could not read $fn: $!"; my $f = $/; undef $/; my $VAR1 = {}; eval(<$fh>); 	$/ = $f; close($fh); %SESSION = %$VAR1; } print header(-cookie=>[CGI::Cookie->new(-name=>'sid',-value=>$SESSION::ID)]); our %Q = %{scalar Vars()};`;

our $end = q`my $fn = $SESSION::PATH . $SESSION::ID; open(my $fh, '>', $fn) or carp "Could not write $fn: $!"; print $fh Dumper \%SESSION; close($fh);`;

our $STATE = 'START';
sub import {
    my ($type) = @_;
    my ($ref) = [];
    filter_add(bless $ref);
}
sub filter {
    my ($self) = @_;
    my ($status);
    if( ($status = filter_read()) > 0 ){
        my $CODE = $STATE eq 'TEXT' ? 'print qq!' : '';
        if($STATE eq 'START'){
        	$STATE = 'TEXT';
        	$CODE = $begin . 'print qq!';
        }
        foreach(split /((?:<\?|\?>).*?)/){
            if(/^<\?/){
                s/^<\?//;
                $STATE = 'PERL';
                $CODE .= '!;';
            }
            elsif(/^\?>/) {
                s/^\?>//;
                $STATE = 'TEXT';
                $CODE .= 'print qq!';
            }
            s/\!/\\!/g if $STATE eq 'TEXT';
            $CODE .= $_;
        }
        $_ = $CODE . ($STATE eq 'TEXT' ? '!;' : '');
        s`</html>`</html>!; $end print qq!`i;
    }    
    $status;
}

1; # End of Filter::PerlTags::Extra
