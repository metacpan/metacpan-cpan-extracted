package Hash::AutoHash::Args::V0;
#################################################################################
#
# Author:  Nat Goodman
# Created: 09-03-05
# $Id: 
#
# Simplifies processing of keyward argument lists.
# Replaces Class::AutoClass::Args using Class::AutoClass:Hash and tied hash to 
# provide cleaner, more powerful interface.
# Completely compatible with Class::AutoClass::Args.
# Use Hash::AutoHash::Args if compatibility with Class::AutoClass::Args NOT needed
#
#################################################################################
use strict;
use Carp;
use Hash::AutoHash;
use base qw(Hash::AutoHash::Args);
our $VERSION='1.18';

our @NORMAL_EXPORT_OK=@Hash::AutoHash::Args::EXPORT_OK;
my $helper_class=__PACKAGE__.'::helper';
our @EXPORT_OK=$helper_class->EXPORT_OK;
our @SUBCLASS_EXPORT_OK=$helper_class->SUBCLASS_EXPORT_OK;

################################################################################
# methods needed for compatibility with Class::AutoClass::Args
# implementations live in Hash::AutoHash::Args::helper
################################################################################
my $helper_class='Hash::AutoHash::Args::helper';
no strict 'refs';
sub get_args { &{$helper_class.'::get_args'} }
sub getall_args { &{$helper_class.'::getall_args'} }
sub set_args { &{$helper_class.'::set_args'} }
sub fix_args { &{$helper_class.'::fix_args'} }
*_fix_args=\&fix_args;
sub fix_keyword { &{$helper_class.'::fix_keyword'} }
sub fix_keywords { &{$helper_class.'::fix_keywords'} }
sub is_keyword { &{$helper_class.'::is_keyword'} }
sub is_positional { &{$helper_class.'::is_positional'} }

#################################################################################
# helper package exists to avoid polluting Hash::AutoHash::Args namespace with
#   subs that would mask accessor/mutator AUTOLOADs
# needed here to get EXPORT_OK, SUBCLASS_EXPORT_OK, import methods from base helper
#################################################################################
package Hash::AutoHash::Args::V0::helper;
our $VERSION=$Hash::AutoHash::Args::V0::VERSION;
use strict;
BEGIN {
  our @ISA=qw(Hash::AutoHash::Args::helper);
}

package Hash::AutoHash::Args::V0; # so CPAN will connect POD to main class

1;

__END__

=head1 NAME

Hash::AutoHash::Args::V0 - Object-oriented processing of argument lists (version 0)

=head1 VERSION

Version 1.18

=head1 SYNOPSIS

  use Hash::AutoHash::Args::V0;
  my $args=new Hash::AutoHash::Args::V0(name=>'Joe',
                                      HOBBIES=>'hiking',hobbies=>'cooking');

  # access argument values as HASH elements
  my $name=$args->{name};
  my $hobbies=$args->{hobbies};

  # access argument values via methods
  my $name=$args->name;
  my $hobbies=$args->hobbies;

  # set local variables from argument values -- three equivalent ways
  use Hash::AutoHash::Args qw(autoargs_get);
  my($name,$hobbies)=@$args{qw(name hobbies)};
  my($name,$hobbies)=autoargs_get($args,qw(name hobbies));
  my($name,$hobbies)=$args->get_args(qw(name hobbies)));

  # copy args into local hash
  my %args=$args->getall_args

  # alias $args to regular hash for more concise hash notation
  use Hash::AutoHash::Args qw(autoargs_alias);
  autoargs_alias($args,%args);
  my($name,$hobbies)=@args{qw(name hobbies)}; # get argument values
  $args{name}='Joseph';                       # set argument value

=head1 DESCRIPTION

This class simplifies the handling of keyword argument lists. It
replaces L<Class::AutoClass::Args>. It is a subclass of
L<Hash::AutoHash::Args> providing almost complete compatibility with
L<Class::AutoClass::Arg>. We recommend that you use
L<Hash::AutoHash::Args> instead of this class unless you need
compatibility with L<Class::AutoClass::Args>.

This class is identical to L<Hash::AutoHash::Args> except as
follows. Please refer to L<Hash::AutoHash::Args> for the main
documentation.

Unlike L<Hash::AutoHash::Args>, this class defines several methods and
functions in its own namespace.

  get_args, getall_args, set_args, fix_args, _fix_args, fix_keyword,
  fix_keywords, is_keyword, is_positional

A consequence of these being defined in the class's namespace is that
they "mask" keywords of the same name and prevent those keywords from
being accessed using method notation. In L<Hash::AutoHash::Args>,
these are provided as functions that can be imported in the caller's
namespace which avoids the masking problem.

get_args, getall_args, and set_args are methods that can be invoked on
Hash::AutoHash::Args::V0 objects. Descriptions of these methods are
below.  The others are functions and operate the same way here as in
L<Hash::AutoHash::Args> except that they do not need to be imported
before use.

 Title   : get_args
 Usage   : ($name,$hobbies)=$args->get_args(qw(-name hobbies))
 Function: Get values for multiple keywords
 Args    : array or ARRAY of keywords
 Returns : array or ARRAY of argument values
 Note    : provided in Hash::AutoHash::Args as importable function

 Title   : getall_args
 Usage   : %args=$args->getall_args;
 Function: Get all keyword, value pairs
 Args    : none
 Returns : hash or HASH of key=>value pairs.
 Note    : provided in Hash::AutoHash::Args as importable function

 Title   : set_args
 Usage   : $args->set_args
             (name=>'Joe the Plumber',-first_name=>'Joe',-last_name=>'Plumber')
 Function: Set multiple arguments in existing object
 Args    : parameter list in same format as for 'new'
 Returns : nothing
 Note    : provided in Hash::AutoHash::Args as importable function


=head1 DIFFERENCES FROM Class::AutoClass::Args

This class differs from its precursor, L<Class::AutoClass::Args>, only
in a bug fix involving get_args in scalar context.

In scalar context, get_args is supposed to return an ARRAY of argument
values. Instead, in Class::AutoClass::Args, it returned the value of the first
argument.

  my $values=$args->get_args(qw(name hobbies)); # old bug: gets value of 'name'

The bug has been fixed and it now returns an ARRAY of the requested argument
values.

  my $values=get_args($args,qw(name hobbies));  # now: gets ARRAY of both values


=head1 SEE ALSO

L<Hash::AutoHash::Args> is the base class of this one.
L<Class::AutoClass::Args> is replaced by this
class. 

L<Hash::AutoHash> provides the object wrapper used by this class.
L<Hash::AutoHash::MultiValued>, L<Hash::AutoHash::AVPairsSingle>,
L<Hash::AutoHash::AVPairsMulti>, L<Hash::AutoHash::Record> are other
subclasses of L<Hash::AutoHash>.

L<perltie> and L<Tie::Hash> present background on tied hashes.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 KNOWN BUGS AND CAVEATS

CPAN reports that "Make test fails under Perl 5.6.2, FreeBSD 5.2.1."
for the predecessor to this class, L<Class::AutoClass::Args>.  We are
not aware of any bugs in this class.

=head2 Bugs, Caveats, and ToDos

See caveats about accessing arguments via method notation.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::AutoHash::Args::V0

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-AutoHash-Args-V0>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-AutoHash-Args-V0>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-AutoHash-Args-V0>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-AutoHash-Args-V0/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008, 2009 Institute for Systems Biology (ISB). All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
