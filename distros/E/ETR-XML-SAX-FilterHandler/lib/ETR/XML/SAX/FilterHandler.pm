package ETR::XML::SAX::FilterHandler;

use 5.006;
use strict;
use warnings;

=head1 NAME

ETR::XML::SAX::FilterHandler - A handler to filter large XML files or streams

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

 use ETR::XML::SAX::FilterHandler;
 use XML::SAX::ParserFactory;
 my $hnd = ETR::XML::SAX::FilterHandler->new({

        root            => books,
        record          => {
                                entry       => 1,
                                other_entry => 1
                        },
        find_data       => {
                                "Title 1" => 1,
                                "Title 3" => 1,
                                Oth       => 1
                        }
 });
 my $str=<<EOS;
 <books>
   <entry>
     <title>Title 1</title>
   </entry>
   <other_entry>
     <title>Other title</title>
   </other_entry>
   <entry>
     <title>Title 2</title>
   </entry>
   <entry>
     <title>Title 3</title>
   </entry>
 </books>
 EOS
 my $factory = XML::SAX::ParserFactory->parser(Handler => $hnd);

 # XML source:

 # from string:
 print "\nfrom string:\n======\n";
 $factory->parse_string($str);

 # from file
 print "\nfrom file:\n======\n";
 $factory->parse_file("books.xml");

 # from standard input
 print "\nfrom standard input:\n======\n";
 $factory->parse_file(*STDIN);

Every time you should receive the following result:

 <books>
   <entry>
     <title>Title 1</title>
   </entry>
   <other_entry>
     <title>Other title</title>
   </other_entry>
   <entry>
     <title>Title 3</title>
   </entry>
 </books>

=head1 DESCRIPTION

Parse large XML files or streams without being loaded into memory and print
to the standard output only the fragments that match to the filtering rules
specified by the two parameters: record and find_data.

=head1 METHODS

=head2 new()

 new({ 
	root	=> document_root,
	record	=> {
		entry1 => 1,
		entry2 => 1,
		...
		entrym => 1
	}
	find_data => {
		str1 => 1,
		str2 => 1,
		...
		strn => 1
	}
 })

=head3 Parameters:

	root:		a string used to enclose the whole document;

	record:		is a hash with element names considered as being record
			delimiters;

	find_data:	the record is printed out if at least one string from this hash 
			matches to the xml data.

	Note: The values from the two hashes have to be set to 1, just to force key to be
	defined.

=cut

sub new {
        my ($type, $arg) = @_;
        #print Dumper($arg->{tag}{entry});
        #print "...filter\n";
        return bless {
                buf     => "",
                open    => 0,
                level   => 0,
                found   => 0,
                isdata  => 0,
                indent  => " ",
                record          => $arg->{record},
                find_data       => $arg->{find_data},
                root            => $arg->{root}
        }, $type;
}

sub start_document{
        my $self = shift;
        print "<$self->{root}>\n" if defined $self->{root};
}

sub end_document{
        my $self = shift;
        #print "End doc\n";
        print "</$self->{root}>\n" if defined $self->{root};
}

sub start_element{
        my ($self, $el) = @_;
        #print "Starting el $el->{Name} \n";
        #print "...record","\n" if defined $self->{record}{$el->{Name}};
        if (defined $self->{record}{$el->{Name}}){
                $self->{buf} = "<$el->{Name}";
                #print Dumper $el->{Attributes};
                $self->add_attr($el->{Attributes});
                $self->{open}  = 1;
                $self->{level} = 0;
                $self->{found} = 0;
                $self->{isdata} = 0;
        }
        elsif($self->{open}){
                $self->{level}++;
                #chomp($el->{Name});
                #print $el->{Name},"\n";
                #print $self->{level},"\n";
                $self->indent;
                $self->{buf} .= "<$el->{Name}" ;
                $self->add_attr($el->{Attributes});
        }
}

sub end_element{
        my ($self, $el) = @_;
        #print "Ending element $el->{Name}\n";
        if (defined $self->{record}{$el->{Name}}){
                $self->{buf} .= "</$el->{Name}>\n";
                $self->{open} = 0;
                #$self->{buf} =~ s/^\s*\n//mg;
                print $self->{buf} if $self->{found};
        }
        elsif ($self->{open}){
                if($self->{isdata}){
                        $self->{isdata} = 0;
                }
                else{
                        $self->{level}--;
                        $self->indent;
                }
                $self->{level}--;
                $self->{buf} .= "</$el->{Name}>\n";
        }
}

sub characters{
        my($self, $char) = @_;
        chomp($char->{Data});
        if($char->{Data} ne ""){
                chomp($self->{buf});
                $self->{isdata} = 1;
        }

        $self->{buf} .= $char->{Data};
        my $find = $self->{find_data};
        foreach(keys (%$find)){
                #print "key=$_","\n";
                $self->{found} = 1 if $char->{Data} =~ $_;
        }
}

sub indent{
        my $self = shift;
        $self->{buf} .= ($self->{indent} x $self->{level});
}
sub add_attr{
        my ($self, $attr) = @_;
        #print Dumper($attr);
        foreach (keys( %$attr)){
                $self->{buf} .= " $attr->{$_}{Name}=\"$attr->{$_}{Value}\"";
        }
        $self->{buf} .= ">\n";
}




=head1 AUTHOR

Daniel Necsoiu, Ericsson, C<< <daniel.necsoiu@gmail.com; daniel.necsoiu@ericsson.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-etr-xml-sax-filterhandler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ETR-XML-SAX-FilterHandler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ETR::XML::SAX::FilterHandler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ETR-XML-SAX-FilterHandler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ETR-XML-SAX-FilterHandler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ETR-XML-SAX-FilterHandler>

=item * Search CPAN

L<http://search.cpan.org/dist/ETR-XML-SAX-FilterHandler/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Necsoiu, Ericsson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of ETR::XML::SAX::FilterHandler
