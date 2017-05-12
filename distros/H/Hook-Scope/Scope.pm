package Hook::Scope;

use 5.008;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter
	DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Hook::Scope ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

@EXPORT_OK = qw( POST PRE );

@EXPORT = qw();

$VERSION = '0.04';

bootstrap Hook::Scope $VERSION;

sub PRE (&) {
  $_[0]->();
}

sub B::NULL::next { return undef }
sub B::NULL::name { return undef }
use B::Generate;
sub optimizer {
  my $op = shift;
  my $cop;

#  print $op->name . "-" . $cop->name . ":" . $cop->file . ":" . $cop->line . "\n";

  my @scope;
  my @scope_code;
  my $start = $op->first();
  my $previous;
  while($start && ref($start) ne 'B::NULL') {
    if($start->name =~/^enter/ && $start->name ne 'entersub') {
      push @scope, $start;
      push @scope_code, [];
    } elsif($start->name =~/^leave/) {
      pop @scope;
      my $entersubs = pop @scope_code;
      if($entersubs) {
	foreach my $entersub (@$entersubs) {
	  if(ref($start) eq 'B::BINOP') {
	    my $lineseq = $start->last();
	    $entersub->sibling->sibling($lineseq->first());
	    $lineseq->first($entersub);
	    $entersub->sibling->next($start->first->next);
	    $start->first->next($entersub);
	  } else {
	    print $start->first . "- $start\n";
	  }
	}
      }
    }

    $previous = $start if($start->next && ref($start->next) eq 'B::COP');

    if($start->name eq 'refgen' &&
       $start->next && $start->next->name eq 'gv' &&
       $start->next->next && $start->next->next->name eq 'entersub') {
      my $entersub = $start->next->next();
      my $gvop = $start->next();
      my $gv;
      if(ref($gvop) eq 'B::PADOP') {
	#this lives in the threaded
	my $cv = $op->find_cv();
	$gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$gvop->padix];
      } else {
	die "No support for non threaded gvs yet\n";
      }
      if($gv->NAME eq 'PRE') {
	my $root_state = $previous->next();
	$previous->sibling($entersub->sibling());
	$previous->next($entersub->next());

	push @{$scope_code[-1]}, $root_state;


      }
    }


#    print scalar @scope . ": " . ($previous ? $previous->name . " -> " : "") . $start->name . "\n";


    

    $start = $start->next();
    
  }

=cut
  walkoptree_filtered(
		      $op,
		      sub {
			return 1 if(opgrep(
					   {
					    name => 'refgen',
					    next => {
						     'name' => 'gv',
						     'next' => {
								'name' => 'entersub' }
						    },
					   }, @_)
				   );


			print $_[0]->name() . "\n";

			return 0;
		      },
		      sub {
			my $gvop = $_[0]->next();
			my $gv;
			if(ref($gvop) eq 'B::PADOP') {
			  #this lives in the threaded
			  my $cv = $op->find_cv();
			  $gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$gvop->padix];
			} else {
			  die "No support for non threaded gvs yet\n";
			}
			return unless ($gv->NAME eq 'PRE');
			my $entersub = $gvop->next();
			print "FOUND A PRE\n";

		      },
		     );
=cut

}

use optimizer 'sub-detect' => \&optimizer;



1;
__END__

=head1 NAME

Hook::Scope - Perl extension for adding hooks for exiting a scope

=head1 SYNOPSIS

  use Hook::Scope; 
  {
    Hook::Scope::POST(sub { print "I just left my scope"});
    print "you will see this first!";
  }
 
  use Hook::Scope qw(POST PRE);   # only POST can be exported
  {
    POST { print "foo" };
    POST  sub { print "bar"}; # can have multiple POSTs, last added, first run

    PRE  { print "this runs first" };
  }

=head1 ABSTRACT

This module allows you to register subroutines to be executed when the scope 
they were registered in, has been left.

=head1 DESCRIPTION

=head2 POST

C<POST> takes a reference to a subroutine or a subroutine name and will 
register that subroutine to be executed when the scope is left.  Note that
even if the scope is left using die(), the subroutine will be executed.

=head2 EXPORT

None by default.  POST can be exported if so required.

=head1 SEE ALSO

L<Hook::LexWrap>

Please report any bugs using the bug report interface at rt.cpan.org or
using E<lt>bug-Hook-Scope@rt.cpan.orgE<gt>

=head1 AUTHOR

Arthur Bergman, E<lt>abergman@cpan.orgE<gt>

Thanks go to Nick Ing-Simmons for the wicked idea of LEAVE;ENTER;.

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
