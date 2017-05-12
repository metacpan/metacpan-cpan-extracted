
package subimp ;

#require HTML::Embperl::Module ;
#@ISA = qw{HTML::Embperl::Module} ;
#HTML::Embperl::Module::init (\*DATA) ;
#1 ;


{
local $/ = undef ;
my $data = <DATA> ;

# compile page

my $pn = __PACKAGE__ ;
HTML::Embperl::Execute ({inputfile => __FILE__, 
			input => \$data,
			mtime => -M __FILE__ ,
			import => 0,
			options => HTML::Embperl::optKeepSrcInMemory,
			package => $pn . $ENV{EMBPERL_EP1COMPAT}}) ;


}

# import subs

sub import

    {
    my $pn = __PACKAGE__ ;
    HTML::Embperl::Execute ({inputfile => __FILE__, 
			    import => 2,
			    package => $pn . $ENV{EMBPERL_EP1COMPAT}}) ;


    1 ;
    }



1 ;



__DATA__



[###### first sub #####]
[$sub tfirst$]

<h2>1.) Here goes some normal html text <h2>

[$endsub$]


[###### second sub #####]
[$sub tsecond $]

2.) Here comes some perl:

[- $foo = 'Hello world' -]

foo = [+ $foo +]<br>
testdata = [+ $testdata +]<br>
params in sub.pm  = [+ "@_" +]

[$endsub$]



[###### table cell #####]
[$sub tabcell $]


<td>[+ $_[0] -> [$row][$col] +]<td>

[$endsub$]


[###### table header #####]
[$sub tabheader $]

<table>
<tr><th>1</th><th>2></th></tr>
<tr>

[$endsub$]


[###### table footer #####]
[$sub tabfooter $]

</tr>
</table>

[$endsub$]
