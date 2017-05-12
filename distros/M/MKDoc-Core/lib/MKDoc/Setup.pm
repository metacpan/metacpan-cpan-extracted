=head1 NAME

MKDoc::Setup - Generic user setup for MKDoc products.

=head1 SUMMARY

L<MKDoc::Setup> provides a generic base class to make user-friendly installation
procedures for applications which are meant to integrate in the L<MKDoc::Core>
framework.

Although this class stands on its two feet, it is a mockup class. It is meant to be
subclassed for different installations.

MKDoc::Setup doesn't do anything useful on it's own, however you can run it 'as is'
for testing purposes, e.g:

  perl -MMKDoc::Setup -e mockup

If you want to see actual subclasses, look at L<MKDoc::Setup::MKDoc> and
L<MKDoc::Setup::Site>.

=head1 Methods which you should know about

=cut
package MKDoc::Setup;
use strict;
use warnings;


# import MKDoc::Setup::<*>
foreach my $include_dir (@INC)
{
    my $dir = "$include_dir/MKDoc/Setup";
    if (-e $dir and -d $dir)
    {
        opendir DD, $dir or do {
            warn "Cannot open directory $dir. Reason: $!";
            next;
        };

        my @modules = map { s/\.pm$//; $_ }
                      grep /\.pm$/,
                      grep !/^\./,
                      readdir (DD);

        closedir DD;

        foreach my $module (@modules)
        {            
            $module =~ /^(\w+)$/;
            $module = $1;

            $INC{"MKDoc/Setup/$module.pm"} && next;
            require "MKDoc/Setup/$module.pm";
            $@ and warn "Cannot require module $module. Reason: $@";
        }
    }
}



=head1 Other methods / functions

=head2 main::mockup()

Just a bit of syntaxic sugar to ease command line usage, i.e.

  perl -MMKDoc::Setup -e mockup

re-write main::mockup() to main::somethingelse() in your
sub-classes.

  sub main::another { __PACKAGE__->new()->process() }

You can then do:

  perl -MMKDoc::Setup -e another

=cut
sub main::mockup { __PACKAGE__->new()->process() }



=head2 $self->keys();

You MUST subclass this method.

In this method you define a list of keys which you want configuration values for
and in the order in which you want them displayed. For example:

  sub keys
  {
      my $self = shift;
      return qw /foo bar baz/;
  }


Might display something like this once run:

  1. Foo: Carrot
  2. Bar: Tomato
  3. Baz: Banana

=cut
sub keys
{
    my $self = shift;
    return qw /foo bar baz/;
}



=head2 $self->label ($key);

You MUST subclass this method.

Returns a human readable label for a given key. In the example above, the
menu displays 'Foo' (notice the capital letter) for a key 'foo'. This is
done as follows:

  sub label
  {
      my $self = shift;

      $_ = shift;
      /foo/ and return 'Foo';
      /bar/ and return 'Bar';
      /baz/ and return 'Baz';
      return;
  }

=cut
sub label
{
    my $self = shift;

    $_ = shift;
    /foo/ and return 'Foo';
    /bar/ and return 'Bar';
    /baz/ and return 'Baz';
    return;
}



=head2 $self->install();

You MUST subclass this method - assuming you want your installer to actually
install things :-)

  sub install
  {
      # some install code here...
      print "\n\nDone.\n";
      exit (0);
  }

=cut
sub install
{
    print "\n\nDone.\n";
    exit (0);
}



=head2 $self->initialize();

You MAY subclass this method.

Initializes $self, the setup object. $self is a hash which contains key / value
pairs for setup config. This method gives you a chance to initialize your object
with sensible, default values before those values are presented to the user.

=cut
sub initialize
{
    my $self = shift;
    $self->{foo} = 'Carrot';
    $self->{bar} = 'Tomato';
    $self->{baz} = 'Banana';
}



=head2 $self->validate();

You MAY subclass this method.

If you must do any tests on the data to make sure it complies witch whichever
validation rules you choose to implement, you can do it by subclassing validate().

Returns TRUE if the object validates, FALSE otherwise.

I suggest your validate method looks like this:

  sub validate
  {
      my $self = shift;
      $self->validate_xxx() &
      $self->validate_yyy() &
      $self->validate_zzz();
  }

  sub validate_xxx
  {
      my $self = shift;
      $self->some_failure_condition() and do {
          print "Meaningful error message;
          return 0;
      };

      return 1;
  }

=cut
sub validate
{
    my $self = shift;

    # For subclasses which don't redefine the validate() method,
    # this block of code does not exist. It's here for testing
    # purposes only.
    ref $self eq 'MKDoc::Setup' and do {
    $self->{'.seen'} || do {
        print "I will fail just once to test the error message\n";
        $self->{'.seen'} = 1;
        return;
        };
    };

    return 1;
}



=head2 $self->display_value ($key);

Returns the same as $self->{$key}, except when $self->{$key} is undef.

When $self->{$key} is undef, the string "(undef") is sent back rather
than the value itself.

This is used by the menu as a way to display the information 'undef'
to the user.

=cut
sub display_value
{
    my $self = shift;
    my $key  = shift;
    my $val  = $self->{$key};
    return defined $val ? $val : '(undef)';
}



=head2 $self->display_error();

When the object does not validate, this method displays a message error
and waits for a keystroke before re-displaying the main menu.

=cut
sub display_error
{
    my $self = shift;
    $self->message_prompt (
    qq |It seems that this configuration is not correct.
Press enter to continue.| );

    $self->{'.state'} = 'display_menu';
}



=head2 $class->new (%args);

Constructor - Creates a new MKDoc::Setup object.

=cut
sub new
{
    my $class = shift;
    $class    = ref $class || $class;

    my $self  = bless { @_ }, $class;
    $self->initialize();
    return $self;
}



=head2 $self->process();

Method which initializes the state of the object to 'display_menu' and starts
the FSM mechanism.

=cut
sub process
{
    my $self = shift;
    $self->initialize();

    my $state = 'display_menu';
    $self->{'.state'} = $state;
    while (1)
    {
        my $state = $self->{'.state'};
        $self->$state();
    }
}



=head2 $self->display_menu();

Displays the main user menu with a list of options to choose from.

=cut
sub display_menu
{
    my $self = shift;

    system ('clear');

    my $count = 0;
    my @keys  = $self->keys();

    for (@keys)
    {
	$count++;
	format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$count . '. ' . $self->label ($_),    $self->display_value ($_)
.

	write();
    }
    
    # print join "\n", map { ++$count . '. ' . $self->label ($_) . ': ' . $self->display_value ($_) } @keys;
    print "\nD. Delete an option\n\n";
    
    print "I. Install with the options above\n";
    
    print "C. Cancel installation\n\n";
    
    print "Input your choice: ";
    my $line = $self->get_stdin_line();
    
    $line =~ /^\d+$/ and $line > 0 and $line <= scalar @keys and do {
	$self->{'.selected'} = $line;
	$self->{'.state'} = 'display_value_set';
    };

    $line =~ /^d$/i and do {
	delete $self->{'.selected'};
	$self->{'.state'} = 'display_value_delete';
    };
    
    $line =~ /^c$/i and do {
	delete $self->{'.selected'};
	$self->{'.state'} = 'cancel';
    };
    
    $line =~ /^i$/i and do {
	delete $self->{'.selected'};
	$self->{'.state'} = 'proceed';
    };
    
}



=head2 $self->display_value_set();

When the user chooses to set a given value to another value, this
method is invoked. It basically prompts the user for the new value.

=cut
sub display_value_set
{
    my $self  = shift;
    my $index = $self->{'.selected'} - 1;
    my @keys  = $self->keys();
    my $key   = $keys[$index];
    my $label = $self->label ($key);
    my $disp  = $self->display_value ($key);
    my $value = $self->{$key};

    $value = $self->message_prompt ("$label [$disp]: ", $value);
    $self->{$key} = $value;
    $self->{'.state'} = 'display_menu';
}



=head2 $self->display_value_delete();

When the user chooses to delete some value, this method is invoked.
It basically prompts the user for which value to delete / undefine.

=cut
sub display_value_delete
{
    my $self = shift;
    my $line = $self->message_prompt ("Input value to delete: ", 'none');
    
    my @keys = $self->keys();
    $line =~ /^\d+$/ and $line > 0 and $line <= scalar @keys and do {
	my $key = $keys[$line - 1];
	delete $self->{$key};
    };
    
    $self->{'.state'} = 'display_menu';
}



=head2 $self->message_prompt ($message, $default_value);

Prompts the user for a value by displaying $message. If the user just
hits 'enter', $default_value is returned instead.

=cut
sub message_prompt
{
    my $self = shift;
    my $message = shift;
    my $default = shift;
    chomp ($message);
    print "\n";
    print $message;
    my $line = $self->get_stdin_line();
    return $line || $default;
}



=head2 $self->cancel();

Cancels the installation process, exits to system.

=cut
sub cancel
{
    my $self = shift;
    print "\nBye.\n";
    exit(0);
}



=head2 $self->proceed();

Invokes $self->validate() first. If there are errors, invokes $self->display_error().

Otherwise if everything's OK invokes $self->install() which performs the installation.

=cut
sub proceed
{
    my $self  = shift;
    my $check = $self->validate();
    if ($check) { $self->{'.state'} = 'install'       }
    else        { $self->{'.state'} = 'display_error' }
}



=head2 $self->get_stdin_line();

Reads one line from <STDIN>, chomps it, and returns it.

=cut
sub get_stdin_line 
{
    my $self = shift;
    my $line = <STDIN>;
    chomp ($line);
    return $line;
}


1;


__END__


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk
