# ------------------------------------------------------------------
# MKDoc::Control_List
# ------------------------------------------------------------------
# Author: Jean-Michel Hiver
# Description: Access Control List generalization
# ------------------------------------------------------------------
package MKDoc::Control_List;
use strict;
use warnings;

our $VERSION = '0.31';


sub new
{
    my $class = shift;
    return bless { @_ }, $class;
}


sub process
{
    my $self = shift;
    $self->{'caller'} = caller;
    my $code = $self->_compile();
    my @res  = $code->();
    return @res;
}


sub _read_data
{
    my $self = shift;
    return $self->{data} || $self->_read_file();
}


sub _read_file
{
    my $self = shift;
    my $file = $self->{file};
    open FP, "<:utf8", $file || die "Cannot read-open $file. Reason: $@";
    my $data = join '', <FP>;
    close FP;
    return $data;
}


sub _compile
{
    my $self = shift;
    $self->{_code} ||= do {
	my $code = $self->_build_code();
	my $VAR1 = undef;
	eval $code;
	$@ && die $@;
	$VAR1;
    };
    
    return $self->{_code};
}


sub _build_code
{
    my $self = shift;
    my $data = $self->_read_data();
    my @res  = ();
    
    push @res, $self->_build_code_header();
    my $count = 0;
    foreach my $line (split /\n/, $data)
    {
	$count++;
	chomp ($line);
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	$line =~ /^#/  && next;
	$line          || next;
	
	push @res, $self->_build_code_condition ($line)   ||
	           $self->_build_code_ret_value ($line)   ||
		   $self->_build_code_rule ($line)        || do {
		       warn "Cannot parse line $count.\n$line";
		       next;
		   };
    }
    push @res, $self->_build_code_footer();
    return join "\n", @res;
}


sub _build_code_header
{
    my $self = shift;
    my $caller = $self->{'caller'};
    return (
	"\$VAR1 = sub { package $caller;",
       );    
}


sub _build_code_condition
{
    my $self = shift;
    my $line = shift;
    $line =~ /^\s*CONDITION\s+/ || return;
    $line =~ s/^\s*CONDITION\s+(\w+)\s+(.*)$/my \$cnd_$1 = do { $2 };/;
    return $line;
}


sub _build_code_ret_value
{
    my $self = shift;
    my $line = shift;
    $line =~ /^\s*RET_VALUE\s+/ || return;
    $line =~ s/^\s*RET_VALUE\s+(\w+)\s+(.*)$/my \$ret_$1 = do { $2 };/;
    return $line;
}


sub _build_code_rule
{
    my $self = shift;
    my $line = shift;
    $line =~ /^\s*RULE\s+.+?\s+WHEN\s+.+\s*/ || return;

    my ($ret_values, $conditions) = $line =~ /^\s*RULE\s+(.+?)\s+WHEN\s+(.+?)\s*$/;
    my @ret_values = $ret_values =~ /(\w+)/g;
    my @conditions = $conditions =~ /(\w+)/g;
    
    my $code = join ' && ', map { "\$cnd_$_" } @conditions;
    $code   .= ' && return ( '  . join ', ', map { "\$ret_$_" } @ret_values;
    $code   .= ' );';
    return $code;
}


sub _build_code_footer
{
    my $self = shift;
    return ( 'return;',
	     '};' );
}


1;


__END__


=head1 NAME

MKDoc::Control_List - Express complex sets of rules with control lists


=head1 SYNOPSIS

    my $control  = new MKDoc::Control_List ( file => security_rules.txt );
    my ($result) = $control->process();


=head1 SUMMARY

Access Control List is a security model which allows much finer control of
resources than other traditional permission systems such as Unix.

MKDoc::Control_List is a generalization of the concept of Access Control Lists.

MKDoc::Control_List lets you define generic configuration files which give you
very high granularity and control over what to do depending on a certain context.


=head1 EXAMPLE

=head2 Introduction

Say you have to implement an expert system for Santa Claus which will automatically
decide for any children which toy to send. The system has to be extremely flexible
and configurable.

Say you have an array of Child objects. Each object has the following methods:

    $child->name();
    $child->age();
    $child->is_boy();
    $child->is_girl();


Your code might look like this:

    local $Current_Child = undef;
    my $control_list = new MKDoc::Control_List ( file => 'toy_config.txt' );

    my %Toys = ();
    foreach my $child (all_children)
    {
        $Current_Child = $child;
        my $name       = $child->name();
        my ($toy)      = $control_list->process();
        $Toys->{$name} = $toy;
    }
    
    print_toy_list (\%Toys);


Now all you need to do is to define that toy_config.txt.

We're going to do it interactively, and see how much control the control lists
can give you.


=head2 A very generic control list

To start simple, we have a very generic toy which we'll give to all children.

   CONDITION always_true    "true"

   RET_VALUE generic_toy    "Gizmo"

   RULE generic_toy WHEN always_true


=head2 Segregating boys and girls

Now, let's say you have two different toys, one for girls and one for boys.

If the gender of a child is not specified we want to fall back on our sex
neutral ghizmo.

The control list would become:

   CONDITION always_true    "true"
   CONDITION isa_boy        $Current_Child->is_boy();
   CONDITION isa_girl       $Current_Child->is_girl();

   RET_VALUE generic_toy    "Gizmo"
   RET_VALUE boy_toy        "Galaxy Warrior"
   RET_VALUE girl_toy       "Doll"

   RULE boy_toy        WHEN isa_boy
   RULE girl_toy       WHEN isa_girl
   RULE generic_toy    WHEN always_true

The order of the RULE statements is primordial! The Control List will return
specified values as soon as all the conditions listed after the WHEN keyword
are satisfied.

So if you had:

   RULE generic_toy    WHEN always_true
   RULE boy_toy        WHEN isa_boy
   RULE girl_toy       WHEN isa_girl

The control list would have ALWAYS returned Gizmos no matter what.


=head2 Segregating the age

According to Santa studies, Girls older than 8 tend to prefer nice clothes
rather than dolls. Boys remain fairly dumb so they're always very happy
with miniature cars.

You want to add a line which defines a condition is_8_or_more as follows:

  CONDITION is_8_or_more   $Current_Child->age() >= 8;

You want to add a toy type:

  RET_VALUE girly_shoes    "Nice Pink Shoes"

And a rule at the top of your control list:

  RULE girly_shoes WHEN isa_girl is_8_or_more

As you can see there are two conditions after the when. The rule is activated
if and only if both conditions are true.


=head2 Summarizing all up

Here's our final control list:

   CONDITION always_true    "true"
   CONDITION isa_boy        $Current_Child->is_boy()
   CONDITION isa_girl       $Current_Child->is_girl()
   CONDITION is_8_or_more   $Current_Child->age() >= 8
   CONDITION is_less_than_8 $Current_Child->age() < 8

   RET_VALUE generic_toy    "Gizmo"
   RET_VALUE boy_toy        "Galaxy Warrior"
   RET_VALUE girl_toy       "Doll"
   RET_VALUE girly_shoes    "Nice Pink Shoes"

   RULE girly_shoes         WHEN isa_girl is_8_or_more
   RULE boy_toy             WHEN isa_boy
   RULE girl_toy            WHEN isa_girl
   RULE generic_toy         WHEN always_true


=head2 More configuration

As you can see it is infinitely customizable to any level of granularity...
Santa Claus likes to offer little girls who are less than 6 and who are
called Mary dining sets?

He doesn't like boys called Chris or Bruno and wants them to have cod liver?

No problem:

   CONDITION always_true     "true"
   CONDITION isa_boy         $Current_Child->is_boy()
   CONDITION isa_girl        $Current_Child->is_girl()
   CONDITION is_8_or_more    $Current_Child->age() >= 8
   CONDITION is_less_than_6  $Current_Child->age() < 6
   CONDITION is_name_mary    $Current_Child->name() =~ /Mary/i
   CONDITION is_name_bruno   $Current_Child->name() =~ /Bruno/i
   CONDITION is_name_chris   $Current_Child->name() =~ /Chris/i

   RET_VALUE generic_toy     "Gizmo"
   RET_VALUE boy_toy         "Galaxy Warrior"
   RET_VALUE girl_toy        "Doll"
   RET_VALUE girly_shoes     "Nice Pink Shoes"
   RET_VALUE dining_set      "Dining Set"
   RET_VALUE cod_liver       "Cod Liver"

   RULE cod_liver            WHEN isa_boy is_name_bruno
   RULE cod_liver            WHEN isa_boy is_name_chris
   RULE dining_set           WHEN isa_girl is_name_mary is_less_than_6
   RULE girly_shoes          WHEN isa_girl is_8_or_more
   RULE boy_toy              WHEN isa_boy
   RULE girl_toy             WHEN isa_girl
   RULE generic_toy          WHEN always_true


=head1 CONFIGURATION SYNTAX

=head2 CONDITION statements

CONDITION statements must be on one line. They define values which
are either TRUE or FALSE. A rule is triggered when all the CONDITIONs
it references are TRUE.

  CONDITION <condition_name> <Perl Expression>

If the perl expression is too big to fit on one line, write a function in
a specific package and call that instead.  By default, expressions operate
in the namespace of the calling package.

  CONDITION foo_condition    MyPackage::is_foo()


=head2 RET_VALUE statements

RET_VALUE statements must be on one line. They define a value to
return when a rule is activated.

  RET_VALUE <ret_value_name> <Perl Expression>

If the perl expression is too big to fit on one line, write a function in
a specific package and call that instead.  By default, expressions operate
in the namespace of the calling package.

  RET_VALUE foo_value    MyPackage::my_ret_value()


=head2 RULE statements

RULEs are the core of the MKDoc::Control_List module. They are processed
one after the other. The first rule which is activated returns a list of
values.

  RULE value1 value2 value3 WHEN condition1 condition2 condition3


=head1 API

=head1 $class->new ( file => 'config_file' );

Returns a new L<MKDoc::Control_List> object.
Can also be initialized with data => $control_list_data.


=head1 $self->process();

Returns a list of values depending which rule is activated.
Returns an empty list if no rule is activated.

Example:

  my @result = $control_list->process();


=head1 EXPORTS

None.


=head1 KNOWN BUGS

None, which probably means plenty of unknown bugs :)


=head1 ABOUT

MKDoc is a web content management system written in Perl which focuses on
standards compliance, accessiblity and usability issues, and multi-lingual
websites.

At MKDoc Ltd we have decided to gradually break up our existing commercial
software into a collection of completely independent, well-documented,
well-tested open-source CPAN modules.

Ultimately we want MKDoc code to be a coherent collection of module
distributions, yet each distribution should be usable and useful in itself.

MKDoc::Control_List is part of this effort.

You could help us and turn some of MKDoc's code into a CPAN module.
You can take a look at the existing code at http://download.mkdoc.org/.

If you are interested in some functionality which you would like to
see as a standalone CPAN module, send an email to <mkdoc-modules@lists.webarch.co.uk>.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut
