package HTML::Obliterate;

use strict;
use warnings;
our $VERSION = '0.3';

use base 'Exporter';
our @EXPORT_OK = qw( 
    remove_html       remove_html_from_string
    obliterate_html   kill_html 
    erase_html        extinguish_html 
    extirpate_html    abolish_html 
    doff_html         eliminate_html 
    drop_html         purge_html 
    strip_html        destroy_html
    defenestrate_html
);

sub remove_html {
    my ($item) = @_;
    
    if(ref $item eq 'ARRAY') {
        my @copy;
        
        for my $i (0 .. (@{ $item } -1)) {
            $item->[$i] = remove_html_from_string($item->[$i]) if !defined wantarray;
            $copy[$i]   = remove_html_from_string($item->[$i]) if defined wantarray;    
        }
        
        return $item if !defined wantarray; # seems kind of pointless but its not, hmm a riddle :)
        return \@copy;
    }
    
    return remove_html_from_string($item);
}

sub remove_html_from_string {
    my($string) = @_;
    $string =~ s{ < \s* [!] \s* [-] \s* [-] \s* .*? [-] \s* [-] \s* > }{}oxms; # comment's w/ posible HTML
    $string =~ s{ < \W* [^>]* > (?: [^<]* >)* }{}oxmsg;
    $string =~ s{ [&][#]? \w+ [;]? }{}oxmsg;
    return $string;
}

sub obliterate_html { goto &HTML::Obliterate::remove_html }
sub kill_html { goto &HTML::Obliterate::remove_html }
sub erase_html { goto &HTML::Obliterate::remove_html }
sub extinguish_html { goto &HTML::Obliterate::remove_html }
sub extirpate_html { goto &HTML::Obliterate::remove_html }
sub abolish_html { goto &HTML::Obliterate::remove_html }
sub doff_html { goto &HTML::Obliterate::remove_html }
sub eliminate_html { goto &HTML::Obliterate::remove_html }
sub drop_html { goto &HTML::Obliterate::remove_html }
sub purge_html { goto &HTML::Obliterate::remove_html }
sub strip_html { goto &HTML::Obliterate::remove_html }
sub destroy_html { goto &HTML::Obliterate::remove_html }
sub defenestrate_html { goto &HTML::Obliterate::remove_html }

1;

__END__

=head1 NAME

HTML::Obliterate - Perl extension to remove HTML from a string or arrayref of strings.

=head1 SYNOPSIS

  use HTML::Obliterate qw(extirpate_html);
  my $html_less_version_of_string = extirpate_html( $html_code_string );

=head1 DESCRIPTION

Removes HTML tags and entities from a string, efficiently and reliably.

=head2 EXPORT

None by default. But all functions can be.

=head1 FUNCTIONS

=head2 remove_html_from_string()

Takes a string, removes all HTML tags and entities, and returns the HTMl-free version.

=head2 remove_html()

Same as remove_html_from_string() except you can also pass it an array ref of strings to have their HTML removed.

In void context it will modify the array passed:

    my @html = ...
    remove_html(\@html);
    # every item in @html now does not have any HTML tags in it

Otherwise it returns an array ref to a new array:

    my @html = ...
    my $html_free = remove_html(\@html);
    # @html is still the same strings, including any HTML tags
    # $html_free is an array ref of an array that is a copy of @html except without any HTML tags

=head2 not the same boring code

Tired of the same old thing? Surprise your wife, impress your boss, and 
amaze your friends with these wild, wacky, alternative aliases to remove_html():

=over 4

=item obliterate_html

=item kill_html 

=item erase_html      

=item extinguish_html 

=item extirpate_html  

My favorite just FYI ;)

=item abolish_html 

=item doff_html       

My second favorite...

=item eliminate_html 

=item drop_html       

=item purge_html 

=item strip_html

=item defenestrate_html

A new favorite

=back

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut