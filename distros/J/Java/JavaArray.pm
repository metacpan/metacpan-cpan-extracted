#
# $Id: JavaArray.pm,v 1.1.1.1 2003/11/17 22:08:07 zzo Exp $
#

package JavaArray;

# Just keep track of java object
# A VERY (ridiculously so perhaps!) thin veneer over the stuff in Java.pm...
sub TIEARRAY
{
        my $class = shift;
        my $java_object = shift;

        return bless {
                java_object => $java_object,
        }, $class;
}

sub FETCH
{
        my($self,$index) = @_;
        $self->get_object->get_field($index);
}

sub STORE
{
        my($self,$index,$value) = @_;
        $self->get_object->set_field($index,$value);
}

sub FETCHSIZE
{
        my($self) = @_;
        $self->get_object->get_length;
}

sub STORESIZE
{
        my($self) = @_;
        $self->FETCHSIZE+1;
}

#sub DESTROY
#{
        #my($self) = @_;
        #$self->get_object->DESTROY;
#}

sub get_object
{
        my($self) = @_;
        $self->{java_object};
}

# Sneaky way to get actual java object outta this thang
#       for function calls & such w/o having to keep around
#       the actual object returned by 'tie'
sub POP
{
        my($self) = @_;
        $self->get_object;
}
1;
__END__

=head1 NAME

JavaArray - Tie'd extension for Java arrays from Java.pm

=head1 SYNOPSIS

  use Java;

  # Set up Java.pm to always return tied array references to me
  my $java = new Java(use_tied_arrays => 1);
  my $tied_array = $java->create_array("java.lang.String",5);

	OR

 # Roll my own tied arrays
	my @tied_array;
  	tie @tied_array, 'JavaArray', $java->create_array("java.lang.String",5);
        	OR
  	tie @tied_array, 'JavaArray', $some_object_that_is_an_array;

  // Set array element 3 to "Java is lame"
  $tied_array[3] = "Java is lame";

  // Get array element 3's value
  my $element = $tied_array[3]->get_value();
  
  // Get length
  my $length = scalar(@tied_array);
  my $size = $#tied_array;

  // Use as parameter you gotta pass the reference!
  my $list = $java->java_util_Arrays("asList",\@tied_array);

  // NO OTHER ARRAY OPERATIONS ARE AVAILABLE!
  //    so no pop or push or unshift or shift or splice
  //    Hey even this can't make Java arrays cool!
  //    use the Collections framework!

=head1 DESCRIPTION

This module puts a pretty thin veneer over Java.pm objects are are Java
arrays.  Makes 'em slightly prettier to play with.
You can pass as an agrument to the 'tie' any Java object that is an array -
either one you created yourself or one that was returned to you by
something else.

You probably should NOT be using this directly, but specify 'use_tied_arrays'
in your constructor args to Java.pm.

=head2 In parameter lists

If you want to use your array in a parameter list you've got to pass in
the REFERENCE to your array or things will go haywire...
If you specified 'use_tied_arrays' in your Java.pm constructor then you
will only receive references back from Java.pm so you've already got the
reference.  ONLY if you call 'tie' yourself (& I can't really think of why
you ever would... BUT) & get the array itself do you need to take its
reference when using it in parameter lists.

=head2 Automatic usage

You can tell Java.pm to automatically convert all Java arrays to their
tied counterparts by setting 'use_tied_arrays' in your Java constructor.
You will get receive a reference to the tied array so you must use the '->'
notation like:

        $array->[3] = "Mark rox";
        my $ele = $array->[4];

See perldoc Java.pm for more info.  You can then use that value directly
in parameter lists.

=head2 EXPORT

None by default.

=head1 AUTHOR

Mark Ethan Trostler, mark@zzo.com

=head1 SEE ALSO

perl(1).
Java.pm.

=cut
