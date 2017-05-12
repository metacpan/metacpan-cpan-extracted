require GetWeb::FormatAnnotated;

package GetWeb::UnformatForm;

use URI::URL;
use GetWeb::Util;
use URI::Escape;

@ISA = qw( GetWeb::FormatAnnotated );

use Carp;
use strict;

sub new
{
    my $type = shift;
    my $pBody = shift;

    my $self = $type -> SUPER::new (@_);
    $$self{formCount} = 'A';
    $$self{pBody} = $pBody;
    bless($self,$type);
    $self;
}

sub form_start
{
    my $self = shift;
    my ($elem) = @_;

    # jfjf support POST, mailto correctly

    $elem -> {phQuery} = {};

    my $letter = $self -> {formCount};
    my $pBody = $self -> {pBody};

    $$pBody =~ s/.*?\<GETWEB: +FORM +$letter\>//
	or $self -> myDie("form $letter not found\n");

    $self -> SUPER::form_start(@_);
}

sub formDie
{
    my ($self, $text) = @_;
    defined $text or $text = "died during form processing\n";

    my $form = $self -> {current_form};
    defined $form or $self -> myDie("no current form, died from $text");

    return if defined $form -> {formDieText};
    $form -> {formDieText} = $text;
    die $text;
}


sub myDie
{
    my ($self, $text) = @_;
    defined $text or $text = "died during form processing\n";

    return if defined $self -> {myDieText};
    $self -> {myDieText} = $text;
    die $text;
}

sub addNameValue
{
    my ($self, $elem, $unique) = @_;

    my $name = $elem -> attr('name');
    my $value = $elem -> attr('value');

    $self -> addKeyVal($name,$value,$unique);
}

sub addKeyVal
{
    my ($self, $key, $val, $unique) = @_;

    # print "(key val is $key $val)\n";
    
    my $phQuery = $self -> {current_form} -> {phQuery};

    my $paVal = $phQuery -> {$key};
    if (! defined $paVal)
    {
	$paVal = [];
	$phQuery -> {$key} = $paVal;
    }
    else
    {
	$unique and
	    $self -> formDie("SYNTAX_ERROR: key '$key' selected more than once: '$val' and '"
			   . $$paVal[0] . "'\n\n" .
			   "Please select only one '$key' attribute.\n");
    }
    
    push(@$paVal,$val);
}

sub input_hidden_start
{
    my $self = shift;
    my ($elem) = @_;

    $self -> addNameValue($elem);
    $self -> SUPER::input_hidden_start(@_);
}

# jfjf implement escaping

sub endsInSlash
{
    my $self = shift;
    my $text = shift;

    $text =~ s/\\(.)/$1/g;

    # print "text is $text.\n";

    $text =~ /\\$/;
}

sub input
{
    my $self = shift;

    my $pBody = $self -> {pBody};

    # jfjf make escaping slashes more consistent

    while (1)
    {
	while (1)
	{
	    $$pBody =~ s/(.*?)\[// or
		$self -> myDie("CORRUPT: could not find next left bracket\n");

	    last unless $self -> endsInSlash($1);
	}
	
	my $input = "";
	while (1)
	{
	    $$pBody =~ s/(.*?)\]// or
		$self -> myDie("CORRUPT: could not find next right bracket\n");
	    $input .= $1;

	    last unless $self -> endsInSlash($input);
	    $input .= "]";
	}

	$input =~ s/\n/ /g;
	# next if $input eq 'IMAGE';
	next if $input =~ /\d/ and $input =~ /^[\dX]+$/i; # href, ignore
	$input =~ s/\\(.)/$1/g;

	# print "found $input\n";
	return $input;
    }
}

sub input_line
{
    my $self = shift;
    
    my $input = $self -> input;
    $input =~ s/__+$/_/g;
    $input =~ s/(?!\\)(.)_$/$1/;
    $input =~ s/^_+//;

    # repeat same statement to get all unescaped intermediate underscores
    $input =~ s/(?!\\)(.)_/$1 /g;
    $input =~ s/(?!\\)(.)_/$1 /g;

    $input =~ s/\\(.)/$1/g;
    
    $input;
}

# jfjf escape numbers in forms

sub input_checkbox
{
    my $self = shift;

    my $input = $self -> input;

    return 1 if $input =~ /X/i and $input =~ /^[\sX]+$/i;
    return 0 if $input =~ /^\s*$/i;
    $self -> formDie("SYNTAX_ERROR: illegal checkbox input: $input\n");
}

sub input_text_start
{
    my $self = shift;
    my ($elem) = @_;

    my $line = $self -> input_line;
    my $name = $elem -> attr('name');
    $self -> addKeyVal($name,$line);

    $self -> SUPER::input_text_start(@_);
}

sub input_submit_start
{
    my $self = shift;
    my ($elem) = @_;

     #print "submit here\n";

    my $check = $self -> input_checkbox;
    
    # sanity check
    my $pBody = $self -> {pBody};
    $$pBody =~ /.+?check preceding box/
	or $self -> myDie("CORRUPT: parsed past submit query\n");
    my $between = $&;
    $between =~ /\[/
	and $` !~ /\\$/
	    and $self -> myDie("CORRUPT: submit not aligned with submit query: $between\n");

    if ($check)
    {
	my $form = $self -> {current_form};
	my $formDieText = $form -> {formDieText};
	defined $formDieText and
	    $self -> myDie($formDieText);

	$form -> {getweb_submit} = 1;

	# jfjf check on if this key-value is correct
	my $name = $elem -> attr('name');
	
	defined $name and
	    $self -> addKeyVal($name,$elem -> attr('value'));
    }
    $self -> SUPER::input_submit_start;
}

# jfj eliminate all form letters from code

sub input_checkbox_start
{
    my $self = shift;
    my ($elem) = @_;

    my $check = $self -> input_checkbox;
    if ($check)
    {
	my $unique = (lc $elem -> attr('type')) eq 'checkbox'?0:1;
	my $key = $elem -> attr('name');
	my $val = $elem -> attr('value');
	$val eq '' and $val = 'on';
	$self -> addKeyVal($key,$val,$unique);
    }

    $self -> SUPER::input_checkbox_start(@_);
}

sub option_start
{
    my $self = shift;
    my ($elem) = @_;

    my $check = $self -> input_checkbox;
    if ($check)
    {
	my $select = $self -> {current_select};
	my $unique = ! $select -> attr('multiple');
	my $val = $elem -> attr('value');
	my $key = $self -> {select_name};

	$self -> addKeyVal($key,$val,$unique);
    }

    $self -> SUPER::option_start(@_);
}

sub textarea_start
{
    my $self = shift;
    my ($elem) = @_;

    # jfj figure out correct newline behavior in textarea

    my $text = "";

    my $rows = $elem -> attr('rows');
    my $i = $rows;
    while ($i--)
    {
	my $line = $self -> input_line;
	if ($line ne "")
	{
	    $text .= "$line\n";
	}
    }

    my $name = $elem -> attr('name');
    $self -> addKeyVal($name,$text);

    $self -> SUPER::textarea_start(@_);
}

1;
