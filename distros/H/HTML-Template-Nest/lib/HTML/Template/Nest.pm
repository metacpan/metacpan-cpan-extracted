package HTML::Template::Nest;

use 5.020001;
use strict;
use warnings;
use File::Spec;
use Carp;
use Data::Dumper;
use HTML::Template;


our $VERSION = '0.03';

sub new{
	my ($class,%opts) = @_;
	my $self = {%opts};

	#defaults
    $self->{comment_tokens} = [ '<!--','-->' ] unless $self->{comment_tokens};
	$self->{name_label} = 'NAME' unless $self->{name_label};
    $self->{template_dir} = '' unless defined $self->{template_dir};
	$self->{template_ext} = '.html' unless defined $self->{template_ext};
	$self->{show_labels} = 0 unless defined $self->{show_labels};

	bless $self,$class;
	return $self;
}


sub template_dir{
	my($self,$dir) = @_;
	confess "Expected a scalar directory name but got a ".ref($dir) if $dir && ref($dir);
	$self->{template_dir} = $dir if $dir;
	return $self->{template_dir};
}
	

sub comment_tokens{
    my ($self,$token1,$token2) = @_;
    if (defined $token1 ){
        $token2 = $token2 || '';
        $self->{'comment_tokens'} = [ $token1, $token2 ];
    }
    return $self->{'comment_tokens'};

}




sub show_labels{
	my ($self,$show) = @_;
	confess "Expected a boolean but got $show" if $show && ! ( $show == 0 || $show == 1 );
	$self->{show_labels} = $show if $show;
	return $self->{show_labels};
}


sub template_ext{
	my ($self,$ext) = @_;
	confess "Expected a scalar extension name but got a ".ref($ext) if defined $ext && ref($ext);
	$self->{template_ext} = $ext if defined $ext;
	return $self->{template_ext};
}
	

sub name_label{
	my ($self,$label) = @_;
	confess "Expected a scalar name label but got a ".ref($label) if defined $label && ref($label);
	$self->{name_label} = $label if $label;
	return $self->{name_label};
}


sub to_html{
    my ($self,$comp) = @_;

    my $html;
    if ( ref($comp) =~ /array/i ){
        $html = $self->_array_to_html( $comp );
    } elsif( ref( $comp ) =~ /hash/i ){
        $html = $self->_hash_to_html( $comp );
    } else {
		$html = $comp;
    }

    return $html;
}



sub _hash_to_html{
    my ($self,$h) = @_;

    confess "Expected a hashref. Instead got a ".ref($h) unless ref($h) =~ /hash/i;

    my $template_name = $h->{ $self->name_label };

    confess 'Encountered hash with no name_label ("'.$self->name_label.'"): '.Dumper( $h ) unless $template_name;

    my $param = {};

    foreach my $k ( keys %$h ){
        next if $k eq $self->name_label;
        $param->{$k} = $self->to_html( $h->{$k} );
    }

    my $filename = File::Spec->catdir(
        $self->template_dir,
        $template_name.$self->template_ext
    );

    my $temp = HTML::Template->new( filename => $filename );
    $temp->param( $_ => $param->{$_} ) foreach keys %$param;

    my $html = $temp->output;
	if ( $self->show_labels ){

        my $ca = $self->{comment_tokens}->[0];
        my $cb = $self->{comment_tokens}->[1];

		$html = "$ca BEGIN $template_name $cb\n$html\n$ca END $template_name $cb\n";
	}

    return $html;

}




sub _array_to_html{

    my ($self, $arr, $delim) = @_;
    die "Expected an array. Instead got a ".ref($arr) unless ref($arr) =~ /array/i;
    my $html = '';
    foreach my $comp (@$arr){
        $html.= $delim if ($delim && $html);
        $html.= $self->to_html( $comp );
    }
    return $html;

}



1;
__END__

=head1 NAME

HTML::Template::Nest - manipulate a nested html template structure via a perl hash

=head1 SYNOPSIS

	page.html:
	<html>
		<head>
			<style>
				div { 
					padding: 20px;
					margin: 20px;
					background-color: yellow;
				}
			</style>
		</head>

		<body>
			<!-- TMPL_VAR NAME=contents -->
		</body>
	</html>
	 


	box.html:
	<div>
		<!-- TMPL_VAR NAME=title -->
	</div>


	use HTML::Template::Nest;

	my $page = {
		NAME => 'page',
		contents => [{
			NAME => 'box',
			title => 'First nested box'
		}]
	};

	push @{$page->{contents}},{
		NAME => 'box',
		title => 'Second nested box'
	};

	my $nest = HTML::Template::Nest->new(
		template_dir => '/html/templates/dir'
	);

	print $nest->to_html( $page );
  
	
	# output:

    <html>
	    <head>
		    <style>
			    div { 
				    padding: 20px;
				    margin: 20px;
				    background-color: yellow;
			    }
		    </style>
	    </head>

	    <body>	    
            <div>
	            First nested box
            </div>
            <div>
	            Second nested box
            </div>
	    </body>
    </html>


=head1 DESCRIPTION

HTML::Template is great because it is simple, and doesn't violate MVC in the uncomfortable way Mason does. However if you want components you can manipulate easily and nest arbitrarily, then the raw interface can be labour intensive to work with. For example, to recreate the example in the synopsis using plain HTML::Template, you would need to do something like:

    # first create and populate the inner templates
    my $box1 = HTML::Template->new( filename => 'box.html' ); 
    $box1->param( title => 'First nested box' );
    my $box2 = HTML::Template->new( filename => 'box.html' );
    $box2->param( title => 'Second nested box' );

    # feed the output to the contents of the parent
    my $page = HTML::Template->new( filename => 'page.html' );
    $page->param( contents => $box1->output.$box2->output );

    print $page->output;


It's easy to see how this quickly becomes inconvenient as the size of the component structure increases. It would be better if a routine could create and fill in the params recursively - and this is where HTML::Template::Nest comes in.


Nest uses HTML::Template to create whatever nested structure of templates you give it. Nest

- accepts the input structure as a hashref
- with each (sub)component as a hashref, 
- and each list of components as an arrayref

ie. the components are represented in terms of the most obvious basic perl datatypes, which means you are free to form your structure in any of the many ways you can manipulate normal hashes/arrays. This ends up being a surprisingly powerful templating system with some great advantages - the most obvious being true separation of controller from view. E.g. lets say you wanted to create a 2 row 2 column table using the following templates:

    table.html:
    <table>
        <!-- TMPL_VAR NAME=rows -->
    </table>

    row.html:
    <tr>
        <!-- TMPL_VAR NAME=columns -->
    </tr>


    column.html 
    <td>
        <!-- TMPL_VAR NAME=value -->
    </td>


If you were feeling masochistic, you could do this:

    my $table = {
        NAME => 'table',
        rows => [{
            NAME => 'table_row',
            columns => [{
                NAME => 'table_column',
                value => 'Row 1 Col 1'
            },{
                NAME => 'table_column',
                value => 'Row 1 Col 2'
            }]
        },{
            NAME => 'table_row',
            columns => [{
                NAME => 'table_column',
                value => 'Row 2 Col 1'
            },{
                NAME => 'table_column',
                value => 'Row 2 Col 2'
            }]
        }]
    };

    print $nest->to_html( $table );

Note how each hashref gets a 'NAME' - this indicates the filename of the template (concat template_ext to get the filename). So 'NAME' is a special indicator. The rest of the variables in the hash are interpreted as fill-in parameters. If the fill in params point to text, then these are filled in directly. However if a fill in param is a hashref, then this is understood as a subcomponent, and turned into html before filling in. If a fill in param points to an arrayref, each element in the list is interpreted first (as a component, sublist or plain text) before the generated html is strung end to end in list order.

You can mix and match text fill-ins vs. sub component fill-ins to your hearts content. For example:

    article.html:
    <div class='article'>
        <div class='columns'>
            <!-- TMPL_VAR NAME=columns -->
        </div>
    </div>


    article_column.html:
    <div class='article-column'>
        <!-- TMPL_VAR NAME=contents -->
    </div>


    my $article = {
        NAME => 'article',
        columns => [
            'Blah blah bla my column 1 is just a lump of text',
            { 
                NAME => 'article_column',
                contents => 'but col 2 is a subcomponent'
       
            }
        ]
    };



(Obviously it's your job to make sure you create a structure that generates desirable html!)

Of course, you don't have to specify your structure with a single declaration - and why would you with the full flexibility of perl behind you? For example it makes sense to create a repeating structure like a table using a loop:


    my $rows = [];
    for my $i (1..2){

        my $cols = [];

        for my $j (1..2){
             push @$cols,{ 
                NAME => 'column',
                value => 'Row $i Col $j'
            };
        }
        
        push @$rows,{
            NAME => 'row',
            columns => $cols
        };

    }

    my $table = { 
        NAME => 'table',
        rows => $rows
    };

    print $nest->to_html( $table );


This is a good moment to explain that HTML::Template::Nest *only* uses the TMPL_VAR declaration from HTML::Template. ie if you want to use TMPL_LOOP, TMPL_INCLUDE, TMPL_IF etc. then HTML::Template::Nest is not for you. Why does HTML::Template::Nest not use these? Because the aim is to create a templating system with all of the processing in the perl, and no processing (other than filling in the template variables) in the template. After all if you are looping in the template, then your view and controller are not separate. (And with HTML::Template::Nest it's so very easy to create repetitive structures, so why would you want this anyway?)



=head1 METHODS

=head2 new

constructor for an HTML::Template::Nest object. 

    my $nest = HTML::Template::Nest->new( %opts );

%opts can contain any of the methods HTML::Template::Nest accepts. For example you can do:

    my $nest = HTML::Template::Nest->new( template_dir => '/my/template/dir' );

or equally:

    my $nest = HTML::Template::Nest->new();
    $nest->template_dir( '/my/template/dir' );

(And you should set template_dir one way or another as a minimum!)


=head2 name_label

The default is NAME (all-caps, case-sensitive). Of course if NAME is interpreted as the filename of the template, then you can't use NAME as one of the variables in your template. ie

    <!-- TMPL_VAR NAME=NAME --> 

will never get populated. If you really are adamant about needing to have a template variable called 'NAME' - or you have some other reason for wanting an alternative label point to your template filename, then you can set name_label:

    $nest->name_label( 'GOOSE' );

    #and now

    my $component = {
        GOOSE => 'name_of_my_component'
        ...
    };


=head2 show_labels

Get/set the show_labels property. This is a boolean with default 0. Setting this to 1 results in adding comments to the output html so you can identify which template output text came from. This is useful in development when you have many templates. E.g. adding 

    $nest->show_labels(1);

to the example in the synopsis results in the following:

    <!-- BEGIN page -->
    <html>
        <head>
            <style>
                div { 
                    padding: 20px;
                    margin: 20px;
                    background-color: yellow;
                }
            </style>
        </head>

        <body>
            
    <!-- BEGIN box -->
    <div>
        First nested box
    </div>
    <!-- END box -->

    <!-- BEGIN box -->
    <div>
        Second nested box
    </div>
    <!-- END box -->

        </body>
    </html>
    <!-- END page -->

What if you're not templating html, and you still want labels? Then you should set comment_tokens to whatever is appropriate for the thing you are templating.


=head2 comment_tokens

Use this in conjunction with show_labels. Get/set the tokens used to define comment labels. Expects a 2 element arrayref. E.g. if you were templating javascript you could do:

    $nest->comment_tokens([ '/*','*/' ]);
    
Now your output will have labels like

    /* BEGIN my_js_file */
    ...
    /* END my_js_file */


You can set the second comment token as an empty string if the language you are templating does not use one. E.g. for Perl:

    $nest->comment_tokens([ '#','' ]);



=head2 template_dir

Get/set the dir where HTML::Template::Nest looks for your templates. E.g.

    $nest->template_dir( '/my/template/dir' );

Now if I have

    my $component = {
        NAME => 'hello',
        ...
    }

and template_ext = '.html', we'll expect to find the template at

    /my/template/dir/hello.html


Note that if you have some kind of directory structure for your templates (ie they are not all in the same directory), you can do something like this:

    my $component = {
        NAME => '/my/component/location',
        contents => 'some contents or other'
    };

HTML::Template::Nest will then prepend NAME with template_dir, append template_ext and look in that location for the file. So in our example if template_dir = '/my/template/dir' and template_ext = '.html' then the template file will be expected to exist at

/my/template/dir/my/component/location.html


Of course if you want components to be nested arbitrarily, it might not make sense to contain them in a prescriptive directory structure. 


=head2 template_ext

Get/set the template extension. This is so you can save typing your template extension all the time if it's always the same. The default is '.html' - however, there is no reason why this templating system could not be used to construct any other type of file (or why you could not use another extension even if you were producing html). So e.g. if you are wanting to manipulate javascript files:

    $nest->template_ext('.js');

then

    my $js_file = {
        NAME => 'some_js_file'
        ...
    }

So here HTML::Template::Nest will look in template_dir for 

some_js_file.js


If you don't want to specify a particular template_ext (presumably because files don't all have the same extension) - then you can do

    $nest->template_ext('');

In this case you would need to have NAME point to the full filename. ie

    $nest->template_ext('');

    my $component = {
        NAME => 'hello.html',
        ...
    }


=head2 to_html

Convert a template structure to html. Expects a hashref containing hashrefs/arrayrefs/plain text. Outputs plain html.

e.g.

    widget.html:
    <div class='widget'>
        <h4>I am a widget</h4>
        <div>
            <!-- TMPL_VAR NAME=widget_body -->
        </div>
    </div>


    widget_body.html:
    <div>
        <div>I am the widget body!</div>    
        <div><!-- TMPL_VAR NAME=some_widget_property --></div>
    </div>


    my $widget = {
        NAME => 'widget',
        widget_body => {
            NAME => 'widget_body',
            some_widget_property => 'Totally useless widget'
        }
    };


    print $nest->to_html( $widget );


    #output:
    <div class='widget'>
        <h4>I am a widget</h4>
        <div>
            <div>
                <div>I am the widget body!</div>    
                <div>Totally useless widget</div>
            </div>
        </div>
    </div>


=head1 SEE ALSO

HTML::Template

=head1 AUTHOR

Tom Gracey tomgracey@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Tom Gracey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
