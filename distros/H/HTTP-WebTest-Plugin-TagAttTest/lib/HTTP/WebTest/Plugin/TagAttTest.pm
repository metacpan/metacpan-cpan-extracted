
package HTTP::WebTest::Plugin::TagAttTest;

use vars qw($VERSION);
$VERSION = '1.00';
=head1 NAME

HTTP::WebTest::Plugin::TagAttTest - Test by tag and attribute existence

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin allows to forbid or require tags and/or attributes in a web page.

=cut

use strict;
use base qw(HTTP::WebTest::Plugin);


#use HTTP::Status;

=head1 TEST PARAMETERS

=for pod_merge copy params

=head2 ignore_case

Determines if case is important.

=head3 Allowed values

C<yes>,C<no>

=head3 Default value

C<no>

=head2 tag_require

A required tag. This is an array of hashs such as C<< require_tag => [{tag=>"script", tag_text=>"spam", attr=>"language",attr_text=>"javascript"}] >>

See also the L</TAG HASH> for a more detailed explaination.


=head3 Allowed values

list of hashes

=head3 Default value

None   (will generate a failed test)

=head2  forbid_tag


A forbidden tag.    This is an array of hashs such as C<< forbid_tag => [{tag=>"script",attr=>"language",attr_text=>"javascript"}] >>

See also the L</TAG HASH> for a more detailed explaination.


=head3 Allowed values

list of hashes

=head3 Default value

None   (will generate a failed test)

=head1 TAG HASH


=head2 tag

tag to forbid

=head2 attr

attribute to forbid


=head2 attr_text

regular expression or text. If text, will do a substring search.


=head2 tag_text

regular expression or text. If text, will do a substring search.

Note that if an element is missing, it will not be considered. So something like
C<require_tag => [{tag=>"title"}]> will assure that a page has a title tag, but the
title tag could be blank.


=cut


sub param_types {
    return q(use_case yesno
            tag_forbid list
        tag_require list);
}

sub get_tag($ $)
{
    my ($page, $tag_name) = @_;
    if (!defined($tag_name))
    {
        return ($page->get_tag) ;
    }
    else
    {
        my $res =  $page->get_tag($tag_name);
        return ($res);
    }
}
sub find_attributes
{

	my( $ok, @attrarr, $attr_search, %attrhash, $attr_text_search, $case_re) = @_;
	for my $attribute (@attrarr)
	{
		#this isn't as simple as for tags, because we can't get just certain attributes.
		#the code can be shortened by combining the two if's, but it was giving me a 
		#headache figuring out all of the possibilities, so I left it for readability.
		#case 6
		if (!defined($attr_search))
		{
			my $attr_content = $attrhash{$attribute};
			$ok = 0 if ($attr_content =~ /$case_re\Q$attr_text_search\E/);
        }

		#case 4
      	if  (!(defined ($attr_text_search)) and ($attribute eq $attr_search))
        {
            $ok = 0;
        }
		#case 5
       	else 
        {
            my $attr_content = $attrhash{$attribute};
            $ok = 0 if ($attr_content =~ /$case_re\Q$attr_text_search\E/);
       	}
	}
}

sub search_tag
{
    my $ok = 1;
    my ($page,$case_re, %tag_search_struct) = @_;
    chomp (%tag_search_struct);
    my $tag_search = $tag_search_struct{"tag"};
    undef $tag_search if ($tag_search eq ''); #an undefined tag causes it to loop through all tags.
    my $tag_text_search = $tag_search_struct{"tag_text"};
    my $attr_search = $tag_search_struct{"attr"};
    undef $attr_search if ($attr_search eq '');
    my $attr_text_search = $tag_search_struct{"attr_text"};
    my @results=();
        
	return(0, "No values for tag searched") unless (defined ($tag_search) or  defined ($attr_search));
	#at this point we start looking for tags
	#there are 6 main cases
	#1, looking for a tag
	#2, looking for a specific tag containing some specific text
	#3, looking for any tag containing some specific text
	#4, looking for an attribute
	#5, looking for an attribute containing some specifice text
	#6, looking for any attribute containing some specific text
	# these can be combined
	while ( my $tagstruct = get_tag($page,$tag_search) )
    {
        my $tag   = $tagstruct->[0];
		next if ($tag =~ m!/!);
        my %attrhash= %{$tagstruct->[1]};
        my @attrarr = @{$tagstruct->[2]};
        #the tag exists so we want to see if the contents match
		#case 1
        $ok = 0 if (defined ($tag_search) and !defined ($tag_text_search)); #if we didn't search a tag, we should continue with the success assumption

		#case 2 or 3
        if  ( defined ($tag_text_search) )
        {
            my $tag_content = $page->get_text;           
            $ok = 0 if ($tag_content =~ /$case_re\Q$tag_text_search\E/);
        }

		#this quits if we hit case 1, 2 or 3 and we aren't looking for cases 4, 5 or 6
        last if (  (!defined ($attr_search) &&  !defined ($attr_text_search)) &&  !($ok));
		
		#look for cases 4, 5, 6
		$ok = find_attributes( $ok, @attrarr, $attr_search, %attrhash, $attr_text_search, $case_re);
		
		#if $ok is 0, one of cases 4,5 or 6 must have failed.
		last if ($ok == 0);       
    }
    return ($ok,  "tag: " . $tag_search . ", tag text: " . $tag_text_search . ", attribute: " . $attr_search . ", attribute text: " . $attr_text_search);
}

sub test_tags
{
    my ($self, $tag_type, $content, $case_re) = @_;
	use HTML::TokeParser;
    my $page = HTML::TokeParser->new(\$content);

    my @results;
    for my $tag_struct (@{$self->test_param( $tag_type, [] )})
    {
        my ($ok, $result) = search_tag( $page, $case_re, %{ $tag_struct });
        push @results, $self->test_result($ok, $result);
    }

    return @results;
}


sub check_response {
    my $self = shift;
    
    # response content   
    my $content = $self->webtest->current_response->content;   
    $self->validate_params(qw(ignore_case
        tag_forbid tag_require));
    
    # ignore case or not?
    my $ignore_case = $self->yesno_test_param('ignore_case');
    my $case_re = $ignore_case ? '(?i)' : '';
    
    # clean test results  
    my @results = ();
    my @ret = (); 
    
    # check for forbidden tag and attribute

	my @forbid  = test_tags($self, 'tag_forbid', $content, $case_re );
	push @ret, ['Forbidden tag and attribute', @results] if @forbid;

	my @require = test_tags( $self,'tag_require', $content, $case_re );
	push @ret, ['Required tag and attribute', @results] if @require;
    return @ret;
}





=head1 COPYRIGHT

Copyright (c) 2003-2004 Edward Fancher.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>


L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins::TextMatchTest>

=cut

1;
