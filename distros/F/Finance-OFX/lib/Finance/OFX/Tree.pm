# Filename: Teee.pm
# Parse the Open Financial Exchange format
# http://www.ofx.net/
# 
# Created January 30, 2008	Brandon Fosdick <bfoz@bfoz.net>
#
# Copyright 2008 Brandon Fosdick <bfoz@bfoz.net> (BSD License)
#
# $Id: Tree.pm,v 1.2 2008/03/04 04:22:27 bfoz Exp $

package Finance::OFX::Tree;

use strict;
use warnings;

our $VERSION = '2';

use HTML::Parser;

sub parse
{
    my $source = shift;

    my @tree;
    my @stack;
    unshift @stack, \@tree;

    my $p = HTML::Parser->new(
	start_h	=> [sub
		    {
			my $data = shift;

			my @content = ();
			push @{$stack[0]}, {name => $data, content => \@content};
			unshift @stack, \@content;
		    }, 'tagname'],
	end_h	=> [sub
		    {	# An end event unwinds the stack by one level
			shift(@stack);
		    }, ''],
	text_h	=> [sub
		    {
			my $data = shift;
			$data =~ s/^\s*//;		# Strip leading whitespace
			$data =~ s/\s*$//;		# Strip trailing whitespace
			return unless length $data;	# Ignore empty strings
			if( scalar(@{$stack[0]}) )
			{
			    print STDERR "Naked text\n";
			    return;
			}
			shift @stack;	# Unwind the vestigal array reference
			@{$stack[0]}[-1]->{content} = $data;
		    }, 'dtext' ]);
    $p->unbroken_text(1);   # Want element contents in single blocks to facilitate parsing
    $p->parse($source);
    \@tree;
}

1;

__END__

=head1 NAME

Finance::OFX::Tree - Convert Open Financial Exchange content into a tree 
similar to L<XML::Parser::EasyTree>

=head1 SYNOPSIS

 use Finance::OFX::Tree
 my $tree = Finance::OFX::Tree::parse($ofxContent);

=head1 DESCRIPTION

C<Finance::OFX::Tree> provides a single function, C<parse()>, that accepts the 
contents of an OFX "file" as a scalar argument and returns a reference to an 
array tree representing the contents of the file. The array tree returned by 
C<parse()> is remarkably similar to that created by L<XML::Parser::EasyTree>.

=head2 NOTE

C<parse()> can't process the OFX header block, only the <OFX> block.

=head2 EXAMPLE

If C<$ofxContent> in the above code is...

 <OFX>
    <SIGNONMSGSRSV1>
 	<SONRS>
 	    <STATUS>
 		<CODE>0
 		<SEVERITY>INFO
 		<MESSAGE>SonRq is successful
 	    </STATUS>
 	    <DTSERVER>20080220161753.501[-8:PST]
 	    <LANGUAGE>ENG
 	    <FI>
 		<ORG>DI
 		<FID>074014187
 	    </FI>
 	</SONRS>
    </SIGNONMSGSRSV1>
 </OFX>

...the resulting array tree will be...

 $VAR1 = [
   {
     'content' => [
       {
         'content' => [
           {
             'content' => [
               {
                 'content' => [
                   {
                     'content' => '0',
                     'name' => 'code'
                   },
                   {
                     'content' => 'INFO',
                     'name' => 'severity'
                   },
                   {
                     'content' => 'SonRq is successful',
                     'name' => 'message'
                   }
                 ],
                 'name' => 'status'
               },
               {
                 'content' => '20080220161753.501[-8:PST]',
                 'name' => 'dtserver'
               },
               {
                 'content' => 'ENG',
                 'name' => 'language'
               },
               {
                 'content' => [
                   {
                     'content' => 'DI',
                     'name' => 'org'
                   },
                   {
                     'content' => '074014187',
                     'name' => 'fid'
                   }
                 ],
                 'name' => 'fi'
               }
             ],
             'name' => 'sonrs'
           }
         ],
         'name' => 'signonmsgsrsv1'
       }
     ],
     'name' => 'ofx'
   }
 ];

=head1 FUNCTIONS

=over

=item $tree = parse($ofx)

C<parse()> accepts a single scalar argument containing the OFX data to be 
parsed and retunrs a reference to an array tree.

=back

=head1 SEE ALSO

L<HTML::Parser>
L<XML::Parser::EasyTree>
L<http://ofx.net>

=head1 WARNING

From C<Finance::Bank::LloydsTSB>:

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHOR

Brandon Fosdick, E<lt>bfoz@bfoz.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Brandon Fosdick <bfoz@bfoz.net>

This software is provided under the terms of the BSD License.

=cut
