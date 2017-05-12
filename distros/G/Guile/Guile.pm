package Guile;

use 5.6.1;
use strict;
use warnings;

our $VERSION = "0.002";

use Carp qw(croak confess);
use Data::Dumper;

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

bootstrap Guile $VERSION;

# AUTO IMPORT START
use Guile::gh;
use Guile::__scm;
use Guile::alist;
use Guile::arbiters;
use Guile::async;
use Guile::backtrace;
use Guile::boolean;
use Guile::chars;
use Guile::continuations;
use Guile::coop_defs;
use Guile::debug;
use Guile::dynl;
use Guile::dynwind;
use Guile::environments;
use Guile::eq;
use Guile::error;
use Guile::eval;
use Guile::evalext;
use Guile::extensions;
use Guile::feature;
use Guile::filesys;
use Guile::fluids;
use Guile::fports;
use Guile::gc;
use Guile::gdb_interface;
use Guile::gdbint;
use Guile::goops;
use Guile::gsubr;
use Guile::guardians;
use Guile::hash;
use Guile::hashtab;
use Guile::hooks;
use Guile::init;
use Guile::ioext;
use Guile::iselect;
use Guile::keywords;
use Guile::lang;
use Guile::list;
use Guile::load;
use Guile::macros;
use Guile::mallocs;
use Guile::modules;
use Guile::net_db;
use Guile::numbers;
use Guile::objects;
use Guile::objprop;
use Guile::options;
use Guile::pairs;
use Guile::ports;
use Guile::posix;
use Guile::print;
use Guile::procprop;
use Guile::procs;
use Guile::properties;
use Guile::ramap;
use Guile::random;
use Guile::rdelim;
use Guile::read;
use Guile::root;
use Guile::rw;
use Guile::scmconfig;
use Guile::scmsigs;
use Guile::script;
use Guile::simpos;
use Guile::smob;
use Guile::snarf;
use Guile::socket;
use Guile::sort;
use Guile::srcprop;
use Guile::stackchk;
use Guile::stacks;
use Guile::stime;
use Guile::strings;
use Guile::strop;
use Guile::strorder;
use Guile::strports;
use Guile::struct;
use Guile::symbols;
use Guile::tag;
use Guile::tags;
use Guile::threads;
use Guile::throw;
use Guile::unif;
use Guile::validate;
use Guile::values;
use Guile::variable;
use Guile::vectors;
use Guile::version;
use Guile::vports;
use Guile::weaks;
# AUTO IMPORT END

# initialized Guile interpreter
init_guile();

# no autoloading here - otherwise one of the parent classes' AUTOLOADs
# give me grief.
sub AUTOLOAD;

# convenience wrapper around lookup and apply
sub call {
  my $proc_name = shift;
  my $proc;

  if (Guile::procedure_p($proc_name)) {
    $proc = $proc_name;
  } else {
    $proc = Guile::lookup($proc_name);
    croak("Guile::call : unable to find procedure \"$proc_name\"")
      unless (Guile::procedure_p($proc));
  }

  return Guile::apply($proc, [@_]);
}

package Guile::SCM;
use Carp qw(croak confess);

use overload   
  '""' => "stringify", 
  '0+' => "numify", 
  '&{}' => "codulate",
  '@{}' => "arrayify",
  'bool'=> "boolate",
  '+'   => sub { push(@_, "+", "+");  goto &binary; },
  '-'   => sub { push(@_, "-", "-");  goto &binary; },
  '*'   => sub { push(@_, "*", "*");  goto &binary; },
  '/'   => sub { push(@_, "/", "/");  goto &binary; },
  fallback => 1;

# create a code reference from an SCM procedure
sub codulate {
  my $self = shift;
  croak("Guile::SCM : Cannot use non-procedure SCM as a code reference.")
    unless Guile::procedure_p($self);
  return sub { Guile::apply($self, [@_]); };
}

# create an array reference from an SCM list or pair
sub arrayify {
  my $self = shift;
  
  croak("Guile::SCM : Cannot use non-list/pair SCM as an array reference.")
    unless Guile::list_p($self) or Guile::pair_p($self);

  return stringify($self);
}

# generic routine that applys a guile procedure to two args as an
# overload for a binary operator.
sub binary {
  my ($self, $arg, $order, $proc_name, $name) = @_;

  # lookup the proc - do this everytime to allow procs to be redefined
  my $proc = Guile::lookup($proc_name);
  croak("Guile::SCM::$name : unable to lookup $proc_name procedure in Guile.")
    unless $proc;

  # compute result
  my $result;
  eval { 
    $result = Guile::call2($proc, ($order?($arg, $self):($self, $arg))); 
  };
  croak("Guile::SCM::add : Guile call failed : $@") if $@;
  return $result;
}

1;
__END__

=pod

=head1 NAME

Guile - Perl interface to the Guile Scheme interpreter.

=head1 SYNOPSIS

  use Guile;

  print "1 + 1 = ", Guile::eval_str("(+ 1 1)"), "\n";

=head1 DESCRIPTION

This module provides an interface to the Gnu Guile system.  You can
find out more about Guile at:

   http://www.gnu.org/software/guile/guile.html.

Guile is an interpreter for the Scheme programming language.  "Scheme
is a statically scoped and properly tail-recursive dialect of the Lisp
programming language invented by Guy Lewis Steele Jr. and Gerald Jay
Sussman."  You can find this quote in the language definition for
Scheme here:

   http://www-swiss.ai.mit.edu/~jaffer/r5rs_toc.html

This module is being developed in order to support the development and
usage of an Inline::Guile module.  The intention is to allow Perl
programmers to intermix Perl and Guile code in their programs and
modules.

=head1 REQUIREMENTS

=over 4

=item 1) Perl 5.6.1

Might work with older versions, but don't count on it. Certainly not 5.005.

=item 2) Guile 1.5.0+

Get the source from http://www.gnu.org/software/guile/guile.html if you can't
find a package for your OS.

=back 4

=head1 WRAPPED FUNCTIONS

This module provides an interface to almost every function available
in libguile.  This encompasses almost the entire C<gh_> and C<scm_>
sets.  In general, any function that takes one or more SCM arguements
and returns an SCM or void will be available.  Many other functions
are also available - see the FUNCTION LIST section below for a
complete list.

Functions are called without their C<scm_>, C<gh_> prefixes in the
Guile namespace.  For example, to call the C function C<gh_cons>, you
write:

   my $cons = Guile::cons($car, $cdr);

In the cases where both a C<gh_> and an C<scm_> funtion exist the
C<gh_> function is used.

No attempt will be made to document all the Guile functions - for that
you must refer to the Guile documentation.  Try "info guile" to get
started.

=head1 CONVENIENCE FUNCTIONS

I've added a few convenience functions that I thought would help make
using Guile from Perl easier.

=head2 call($proc_name, @args)

This is equivalent to C<apply(lookup($proc_name), \@args)>.  It allows
you to pass the name of the procedure to call instead of a Guile
procedure object (although that will work too).

=head1 GUILE DATA

Guile has a single datatype called an SCM.  You can create an SCM by
calling the new() method in the Guile::SCM package:

   my $scm = new Guile::SCM;

This creats an SCM with the "undefined" value (aka SCM_UNDEFINED).  To
create an SCM with a more useful value you call new with an argument:

   # to create a string SCM:
   my $scm = new Guile::SCM "foo";

   # an integer
   my $scm = new Guile::SCM 100_000;

   # a floating-point number
   my $scm = new Guile::SCM 10.5e5;

   # a list of integers
   my $scm = new Guile::SCM [ 10, 20, 30, 40 ]

   # a list of mixed types
   my $scm = new Guile::SCM [ 10, "foo", 30, 40.5 ]

The above calls determine the type of the SCM automatically.  This
works well for constants but not so well for variables.  For example,
the code below doesn't create an integer SCM with the value 100:

   my $number = 10;
   $number .= "0";
   my $scm = new Guile::SCM $number;

That's because Perl transformed the $number into a string scalar in
order to concatenate "0" to it.  Thus, new() created an SCM with the
string value "100".  The difference doesn't matter to Perl but a Guile
function you call might not be expecting a string instead of a number.
To solve this problem, you need to create the SCM with an explicit
type:

   my $scm = new Guile::SCM integer => $number;

Another reason to use an explicit type is to create types that have no
obvious corollary in Perl, like a pair.  Normally Guile assumes that
array-refs should be translated into lists.  To create a pair you need
to specify the "pair" type and a reference to a two-element array:

   my $scm = new Guile::SCM pair => ["foo", 20];

The following types are available for use with new():

   integer
   real
   string
   symbol
   list
   pair

For each of these types Guile has a predicate function for identifying
them.  In Guile these functions end in a "?".  In the Perl interface
they have a "_p" ending instead.  These functions return a boolean
indicating if their argument is of the specified type:

  # prints 1
  my $scm = new Guile::SCM integer => 10;
  print "1\n" if Guile::integer_p($scm);

=head1 OVERLOAD MAGIC

The Guile::SCM class provides an overload interface for most
overloaded operations.  

=head2 Math

Mathematic operations on Guile::SCM objects are handled with Guile's
procedures:

   my $one = new Guile::SCM 1;
   my $two = new Guile::SCM 2;
   my $three = $one + $two;

In the above example $three contains an SCM with the integer value 3.
The addition is performed inside Guile - no conversion to Perl
datatypes is requied.  This doesn't matter much in general practice
but it allows greater flexibility in handling Guile data that Perl
would have a difficult time representing like large integers and
floating point numbers.

=head2 Array Accessors

You can treat Guile lists and pairs as arrays from Perl:

  my $list = new Guile::SCM [ 'foo', 'bar', 1, 2 ];
  print "Guile, say foo: ", $list->[0], "\n";

Will print:

  Guile, say foo: foo

This works for list structures of any complexity:

  my $alist = Guile::SCM->new([ Guile::SCM->new(pair => [ foo => 1 ]),
                                Guile::SCM->new(pair => [ bar => 2 ]) ]);
  print "Foo: ", $alist->[0][1], "\n",
        "Bar: ", $alist->[1][1], "\n";

Will print:

  Foo: 1
  Bar: 2

Schemers in the audience will recognize the above as an associative
list.  Eventually I'd like to support hash accessors for such
structures.  See the TODO section for all manner of crazy schemes like
this.

=head2 Code Accessors

The Guile::SCM object also provides an overloaded procedure call
interface.  This can be used to call procedures and closures in Guile.
For example, if you lookup a procedure by name, you can then call the
procedure:

   my $add = Guile::lookup("+");
   my $result = $add->($arg1, $arg2);

=head1 AUTOMATIC SCM CREATION

It may seem like a lot of work to create an SCM.  It is, but it's very
rarely necessary.  For example, the below does just what you'd expect
it to:

   my $cell = Guile::cons(1, 2);

Creates a cons cell (aka pair) out of the values 1 and 2.  These
values are auto-translated into SCMs using the single argument form of
Guile::SCM::new() above.  This is the same thing, writen out:

  my $cell = Guile::cons(Guile::SCM::new(1), Guile::SCM::new(2));

Any Guile function that expects an SCM for an argument will accept
Perl variables and attempt to auto-convert them to SCMs.  Not all Perl
types can be auto-converted at this time - see the docs above for
Guile::SCM::new() for the current list.

=head1 TODO

This module is in an early alpha state.  Many important things still
don't work.  Here's an incomplete list of TODO items:

=over 4

=item * ports

I'd like to be able to pass ports and filehandles back and forth
between Guile and Perl.  It seems do-able but requires a rather
elaborate tie system.

=item * hashes

This should be pretty easy but probably isn't a high priority.  Guile
doesn't encourage a lot of hash usage.

=item * associative lists

Schemers don't use a lot of hashes but they do use associative lists.
Currently these are supported with the same tools Schemers always use.
I'd also like to give them a hash interface to make things easier on
Perl programmers.  This is another complicated tie project.

=item * vectors and arrays

Their fixed dimensions don't make for an obvious mapping into Perl.
Perhaps a PDL mapping?  Or a specialized tied object?

=item * big numbers, big floats, big problems

Guile supports a much more robust numeric system than Perl.  Possible
integration of Math::BigInt and Math::BigFloat?  This probably
requires a more mathy mind than mine.

=item * objects (?)

Two uninhibited object systems meet and... explode?

=item * callbacks into Perl

This seems easy enough but the API needs to be carefully designed.  A
good implementation could lead to a Inline::CPR type thing for Guile
that would give Guile programmers access to Perl.  Egads!

I'd like this interface to allow passing of closures back and forth
between Guile and Perl.  It already works from Guile => Perl.

=item * continuations

I have no idea what needs to be done or what might be possible here.
I serriously doubt Perl will ever support continuations in a
meaningful way.  Does that mean they can't work with Guile.pm?  I'm
not sure.

=back 4

=head1 BUGS

Sometimes Guile will dump core if you give it arguments it wasn't expecting.  For example, if you do

  Guile::cdr(1);

You should expect a core dump.  I don't know if I'm in the right
position to fix this since it seems to me more like a problem inside
Guile itself.

If you find yourself getting core dumps, try using Guile::write() to
examine the data you're passing to Guile functions.  You might also
consider coding defensively using the predicate functions (*_p) to
verify the type of the data you're working with.

=head1 GETTING INVOLVED

This project is just starting and the more people that get involved
the better.  For the time being we can use the Inline mailing-list to
get organized.  Send a blank message to inline-subscribe@perl.org to
join the list.

If you just want to report a bug (just one?) or tell how sick the
whole idea makes you then you can email me directly at sam@tregar.com.

=head1 FUNCTION LIST

The following list contains the name and prototype of every wrapped
libguile function.  Please see the Guile documentation for more
information.

=head2 FUNCTION LIST

   abs($;$)
   accept($;$)
   access($;$$)
   accessor_method_slot_definition($;$)
   acons($;$$$)
   acosh($;$)
   add_hook_x($;$$$)
   add_method($$)
   aind($;$$$)
   alarm($;$)
   angle($;$)
   append($;$)
   append2($;$$)
   append3($;$$$)
   append4($;$$$$)
   append_x($;$)
   apply($;$$)
   apply_0($;$$)
   apply_1($;$$$)
   apply_2($;$$$$)
   apply_3($;$$$$$)
   apply_generic($;$$)
   apply_with_dynamic_root($;$$$$)
   array_contents($;$$)
   array_copy_x($;$$)
   array_dimensions($;$)
   array_equal_p($;$$)
   array_fill_int($;$$$)
   array_fill_x($;$$)
   array_for_each($;$$$)
   array_identity($;$$)
   array_in_bounds_p($;$$)
   array_index_map_x($;$$)
   array_map_x($;$$$)
   array_p($;$$)
   array_prototype($;$)
   array_rank($;$)
   array_set_x($;$$$)
   ash($;$$)
   asinh($;$)
   assoc($;$$)
   assoc_ref($;$$)
   assoc_remove_x($;$$)
   assoc_set_x($;$$$)
   assq($;$$)
   assq_ref($;$$)
   assq_remove_x($;$$)
   assq_set_x($;$$$)
   assv($;$$)
   assv_ref($;$$)
   assv_remove_x($;$$)
   assv_set_x($;$$$)
   async($;$)
   async_click
   async_mark($;$)
   asyncs_pending($;)
   atanh($;$)
   backtrace($;)
   badargsp($;$$)
   basename($;$$)
   basic_basic_make_class($;$$$$)
   basic_make_class($;$$$$)
   big2dbl($;$)
   bigcomp($;$$)
   bigequal($;$$)
   bind($;$$$$)
   bit_count($;$$)
   bit_count_star($;$$$)
   bit_extract($;$$$)
   bit_invert_x($;$)
   bit_position($;$$$)
   bit_set_star_x($;$$$)
   bool2scm($;$)
   boolean_p($;$)
   builtin_variable($;$)
   c_define($;$$)
   c_environment_cell($;$$$)
   c_environment_ref($;$$)
   c_eval_string($;$)
   c_get_internal_run_time($;)
   c_lookup($;$)
   c_make_keyword($;$)
   c_memq($;$$)
   c_module_define($;$$$)
   c_module_lookup($;$$)
   c_primitive_load($;$)
   c_primitive_load_path($;$)
   c_read_string($;$)
   c_resolve_module($;$)
   c_run_hook($$)
   c_use_module($)
   caaar($;$)
   caadr($;$)
   caar($;$)
   cadar($;$)
   caddr($;$)
   cadr($;$)
   call0($;$)
   call1($;$$)
   call2($;$$$)
   call3($;$$$$)
   call_0($;$)
   call_1($;$$)
   call_2($;$$$)
   call_3($;$$$$)
   call_4($;$$$$$)
   call_generic_0($;$)
   call_generic_1($;$$)
   call_generic_2($;$$$)
   call_generic_3($;$$$$)
   call_with_dynamic_root($;$$)
   call_with_input_string($;$$)
   call_with_new_thread($;$)
   call_with_output_string($;$)
   car($;$)
   casei_streq($;$$)
   catch($;$$$)
   cdaar($;$)
   cdadr($;$)
   cdar($;$)
   cddar($;$)
   cdddr($;$)
   cddr($;$)
   cdr($;$)
   cellp($;$)
   ceval($;$$)
   char_alphabetic_p($;$)
   char_ci_eq_p($;$$)
   char_ci_geq_p($;$$)
   char_ci_gr_p($;$$)
   char_ci_leq_p($;$$)
   char_ci_less_p($;$$)
   char_downcase($;$)
   char_eq_p($;$$)
   char_geq_p($;$$)
   char_gr_p($;$$)
   char_is_both_p($;$)
   char_leq_p($;$$)
   char_less_p($;$$)
   char_lower_case_p($;$)
   char_numeric_p($;$)
   char_p($;$)
   char_ready_p($;$)
   char_to_integer($;$)
   char_upcase($;$)
   char_upper_case_p($;$)
   char_whitespace_p($;$)
   chars2byvect($;$$)
   chdir($;$)
   chmod($;$$)
   chown($;$$$)
   chroot($;$)
   class_direct_methods($;$)
   class_direct_slots($;$)
   class_direct_subclasses($;$)
   class_direct_supers($;$)
   class_environment($;$)
   class_name($;$)
   class_of($;$)
   class_precedence_list($;$)
   class_slots($;$)
   clear_registered_modules($;)
   close($;$)
   close_all_ports_except($;$)
   close_fdes($;$)
   close_input_port($;$)
   close_output_port($;$)
   close_pipe($;$)
   close_port($;$)
   closedir($;$)
   closure($;$$)
   closure_p($;$)
   complex_equalp($;$$)
   compute_applicable_methods($;$$$$)
   connect($;$$$$)
   cons($;$$)
   cons2($;$$$)
   cons_source($;$$$)
   cons_star($;$$)
   copy_file($;$$)
   copy_random_state($;$)
   copy_tree($;$)
   copybig($;$$)
   crypt($;$$)
   ctermid($;)
   current_error_port($;)
   current_input_port($;)
   current_load_port($;)
   current_module($;)
   current_module_lookup_closure($;)
   current_module_transformer($;)
   current_output_port($;)
   current_time($;)
   cuserid($;)
   dapply($;$$$)
   dbl2big($;$)
   debug_object_p($;$)
   debug_options($;$)
   define($;$$)
   definedp($;$$)
   delete($;$$)
   delete1_x($;$$)
   delete_file($;$)
   delete_x($;$$)
   delq($;$$)
   delq1_x($;$$)
   delq_x($;$$)
   delv($;$$)
   delv1_x($;$$)
   delv_x($;$$)
   destroy_guardian_x($;$)
   deval($;$$)
   deval_args($;$$$$)
   difference($;$$)
   dimensions_to_uniform_array($;$$$)
   directory_stream_p($;$)
   dirname($;$)
   display($)
   display_application($;$$$)
   display_backtrace($;$$$$)
   display_error($;$$$$$$)
   display_error_message($$$)
   divide($;$$)
   done_free($)
   done_malloc($)
   double2scm($;$)
   doubly_weak_hash_table_p($;$)
   dowinds($$)
   drain_input($;$)
   dup2($;$$)
   dup_to_fdes($;$$)
   dynamic_args_call($;$$$)
   dynamic_call($;$$)
   dynamic_func($;$$)
   dynamic_link($;$)
   dynamic_object_p($;$)
   dynamic_root($;)
   dynamic_unlink($;$)
   dynamic_wind($;$$$)
   enable_primitive_generic_x($;$)
   enclose_array($;$$)
   end_input($)
   ensure_accessor($;$)
   ensure_user_module($;$)
   entity_p($;$)
   env_module($;$)
   env_top_level($;$)
   environ($;$)
   environment_bound_p($;$$)
   environment_cell($;$$$)
   environment_define($;$$$)
   environment_fold($;$$$)
   environment_observe($;$$)
   environment_observe_weak($;$$)
   environment_p($;$)
   environment_ref($;$$)
   environment_set_x($;$$$)
   environment_undefine($;$$)
   environment_unobserve($;$)
   environments_prehistory
   eof_object_p($;$)
   eq_p($;$$)
   equal_p($;$$)
   eqv_p($;$$)
   eval($;$$)
   eval2($;$$)
   eval_0str($;$)
   eval_3($;$$$)
   eval_args($;$$$)
   eval_body($;$$)
   eval_car($;$$)
   eval_closure_lookup($;$$$)
   eval_environment_imported($;$)
   eval_environment_local($;$)
   eval_environment_p($;$)
   eval_environment_set_imported_x($;$$)
   eval_environment_set_local_x($;$$)
   eval_file($;$)
   eval_file_with_standard_handler($;$)
   eval_options_interface($;$)
   eval_str($;$)
   eval_str_with_stack_saving_handler($;$)
   eval_str_with_standard_handler($;$)
   eval_string($;$)
   eval_x($;$$)
   evaluator_traps($;$)
   even_p($;$)
   evict_ports($)
   exact_p($;$)
   exact_to_inexact($;$)
   execl($;$$)
   execle($;$$$)
   execlp($;$$)
   exit_status($;$)
   export_environment_p($;$)
   export_environment_private($;$)
   export_environment_set_private_x($;$$)
   export_environment_set_signature_x($;$$)
   export_environment_signature($;$)
   fcntl($;$$$)
   fdes_to_port($;$$$)
   fdes_to_ports($;$)
   fdopen($;$$)
   file_port_p($;$)
   fileno($;$)
   fill_input($;$)
   find_executable($;$)
   find_method($;$)
   finish_srcprop
   flock($;$$)
   fluid_p($;$)
   fluid_ref($;$)
   fluid_set_x($;$$)
   flush($)
   flush_all_ports($;)
   flush_ws($;$$)
   for_each($;$$$)
   force($;$)
   force_output($;$)
   fork($;)
   frame_arguments($;$)
   frame_evaluating_args_p($;$)
   frame_next($;$)
   frame_number($;$)
   frame_overflow_p($;$)
   frame_p($;$)
   frame_previous($;$)
   frame_procedure($;$)
   frame_procedure_p($;$)
   frame_real_p($;$)
   frame_source($;$)
   free_print_state($)
   free_subr_entry($)
   fsync($;$)
   ftell($;$)
   gc($;)
   gc_mark($)
   gc_mark_cell_conservatively($)
   gc_mark_dependencies($)
   gc_protect_object($;$)
   gc_register_root($)
   gc_stats($;)
   gc_sweep
   gc_unprotect_object($;$)
   gc_unregister_root($)
   gcd($;$$)
   generic_capability_p($;$)
   generic_function_methods($;$)
   generic_function_name($;$)
   gensym($;$)
   gentemp($;$$)
   geq_p($;$$)
   get_internal_real_time($;)
   get_internal_run_time($;)
   get_keyword($;$$$)
   get_one_zombie($;$)
   get_output_string($;$)
   get_pre_modules_obarray($;)
   get_print_state($;$)
   getc($;$)
   getcwd($;)
   getegid($;)
   getenv($;$)
   geteuid($;)
   getgid($;)
   getgrgid($;$)
   getgroups($;)
   gethost($;$)
   gethostname($;)
   getlogin($;)
   getnet($;$)
   getpass($;$)
   getpeername($;$)
   getpgrp($;)
   getpid($;)
   getppid($;)
   getpriority($;$$)
   getproto($;$)
   getpwuid($;$)
   getserv($;$$)
   getsockname($;$)
   getsockopt($;$$$)
   gettimeofday($;)
   getuid($;)
   gmtime($;$)
   goops_version($;)
   gr_p($;$$)
   grow_tok_buf($;$)
   gsubr_apply($;$)
   guard($;$$$)
   guardian_destroyed_p($;$)
   guardian_greedy_p($;$)
   hash($;$$)
   hash_create_handle_x($;$$$)
   hash_fold($;$$$)
   hash_get_handle($;$$)
   hash_ref($;$$$)
   hash_remove_x($;$$)
   hash_set_x($;$$$)
   hashq($;$$)
   hashq_create_handle_x($;$$$)
   hashq_get_handle($;$$)
   hashq_ref($;$$$)
   hashq_remove_x($;$$)
   hashq_set_x($;$$$)
   hashv($;$$)
   hashv_create_handle_x($;$$$)
   hashv_get_handle($;$$)
   hashv_ref($;$$$)
   hashv_remove_x($;$$)
   hashv_set_x($;$$$)
   hashx_create_handle_x($;$$$$$)
   hashx_get_handle($;$$$$)
   hashx_ref($;$$$$$)
   hashx_remove_x($;$$$$$)
   hashx_set_x($;$$$$$)
   hook_empty_p($;$)
   hook_p($;$)
   hook_to_list($;$)
   htonl($;$)
   htons($;$)
   i_big2dbl($;$)
   i_copybig($;$$)
   i_dbl2big($;$)
   i_display_error($$$$$$)
   i_eval($;$$)
   i_eval_x($;$$)
   i_get_keyword($;$$$$$)
   i_int2big($;$)
   i_long2big($;$)
   i_normbig($;$)
   i_procedure_arity($;$)
   igc($)
   ilength($;$)
   ilookup($;$$)
   imag_part($;$)
   import_environment_imports($;$)
   import_environment_p($;$)
   import_environment_set_imports_x($;$$)
   inet_aton($;$)
   inet_makeaddr($;$$)
   inet_netof($;$)
   inet_ntoa($;$)
   inet_ntop($;$$)
   inet_pton($;$$)
   inexact_p($;$)
   inexact_to_exact($;$)
   init_dynamic_linking
   init_goops_builtins($;)
   init_guile
   init_load_path
   init_rdelim_builtins($;)
   init_rw_builtins($;)
   init_storage($;)
   init_subr_table
   init_symbols_deprecated
   input_port_p($;$)
   instance_p($;$)
   int2num($;$)
   int2scm($;$)
   integer_expt($;$$)
   integer_length($;$)
   integer_p($;$)
   integer_to_char($;$)
   interaction_environment($;)
   intern0($;$)
   intern_symbol($;$$)
   internal_parse_path($;$$)
   intprint($$$)
   ipruk($$$)
   isatty_p($;$)
   istr2bve($;$$)
   istr2flo($;$$$)
   istr2int($;$$$)
   istring2number($;$$$)
   ithrow($;$$$)
   join_thread($;$)
   keyword_dash_symbol($;$)
   keyword_p($;$)
   kill($;$$)
   last_pair($;$)
   last_stack_frame($;$)
   lazy_catch($;$$$)
   lcm($;$$)
   leaf_environment_p($;$)
   length($;$)
   leq_p($;$$)
   less_p($;$$)
   link($;$$)
   list($;$)
   list_1($;$)
   list_2($;$$)
   list_3($;$$$)
   list_4($;$$$$)
   list_5($;$$$$$)
   list_cdr_set_x($;$$$)
   list_copy($;$)
   list_head($;$$)
   list_p($;$)
   list_ref($;$$)
   list_set_x($;$$$)
   list_tail($;$$)
   list_to_uniform_array($;$$$)
   listen($;$$)
   lnaof($;$)
   load_extension($;$$)
   load_goops
   load_scheme_module($;$)
   load_startup_files
   local_eval($;$$)
   localtime($;$$)
   lock_mutex($;$)
   logand($;$$)
   logbit_p($;$$)
   logcount($;$)
   logior($;$$)
   lognot($;$)
   logtest($;$$)
   logxor($;$$)
   long2num($;$)
   long2scm($;$)
   lookup($;$)
   lookup_closure_module($;$)
   lookupcar($;$$$)
   lreadparen($;$$$$)
   lreadr($;$$$)
   lreadrecparen($;$$$$)
   lstat($;$)
   m_0_cond($;$$)
   m_0_ify($;$$)
   m_1_ify($;$$)
   m_and($;$$)
   m_apply($;$$)
   m_at_call_with_values($;$$)
   m_atbind($;$$)
   m_atdispatch($;$$)
   m_atfop($;$$)
   m_atslot_ref($;$$)
   m_atslot_set_x($;$$)
   m_begin($;$$)
   m_case($;$$)
   m_cond($;$$)
   m_cont($;$$)
   m_define($;$$)
   m_delay($;$$)
   m_do($;$$)
   m_expand_body($;$$)
   m_generalized_set_x($;$$)
   m_if($;$$)
   m_lambda($;$$)
   m_let($;$$)
   m_letrec($;$$)
   m_letstar($;$$)
   m_nil_cond($;$$)
   m_nil_ify($;$$)
   m_or($;$$)
   m_quasiquote($;$$)
   m_quote($;$$)
   m_set_x($;$$)
   m_t_ify($;$$)
   m_undefine($;$$)
   m_vref($;$$)
   m_vset($;$$)
   m_while($;$$)
   macro_name($;$)
   macro_p($;$)
   macro_transformer($;$)
   macro_type($;$)
   macroexp($;$$)
   magnitude($;$)
   major_version($;)
   makacro($;$)
   make($;$)
   make_arbiter($;$)
   make_class_object($;$$)
   make_complex($;$$)
   make_condition_variable($;)
   make_doubly_weak_hash_table($;$)
   make_eval_environment($;$$)
   make_export_environment($;$$)
   make_extended_class($;$)
   make_fluid($;)
   make_foreign_object($;$$)
   make_guardian($;$)
   make_hook($;$)
   make_import_environment($;$$)
   make_initial_fluids($;)
   make_keyword_from_dash_symbol($;$)
   make_leaf_environment($;)
   make_memoized($;$$)
   make_method_cache($;$)
   make_module($;$)
   make_mutex($;)
   make_next_method($;$$$)
   make_polar($;$$)
   make_port_classes($$)
   make_print_state($;)
   make_procedure_with_setter($;$$)
   make_ra($;$)
   make_real($;$)
   make_rectangular($;$$)
   make_root($;$)
   make_shared_array($;$$$)
   make_shared_substring($;$$$)
   make_soft_port($;$$)
   make_srcprops($;$$$$$)
   make_stack($;$$)
   make_string($;$$)
   make_struct($;$$$)
   make_struct_layout($;$)
   make_subclass_object($;$$)
   make_undefined_variable($;)
   make_uve($;$$)
   make_variable($;$)
   make_vector($;$$)
   make_vtable_vtable($;$$$)
   make_weak_key_hash_table($;$)
   make_weak_value_hash_table($;$)
   make_weak_vector($;$$)
   makfrom0str($;$)
   makfrom0str_opt($;$)
   makmacro($;$)
   makmmacro($;$)
   makprom($;$)
   map($;$$$)
   mark0($;$)
   mark_subr_table
   markcdr($;$)
   markstream($;$)
   mask_signals($;)
   max($;$$)
   mcache_compute_cmethod($;$$)
   mcache_lookup_cmethod($;$$)
   member($;$$)
   memoize_method($;$$)
   memoized_environment($;$)
   memoized_p($;$)
   memq($;$$)
   memv($;$$)
   merge($;$$$)
   merge_x($;$$$)
   method_generic_function($;$)
   method_procedure($;$)
   method_specializers($;$)
   micro_version($;)
   min($;$$)
   minor_version($;)
   mkdir($;$$)
   mknod($;$$$$)
   mkstemp($;$)
   mkstrport($;$$$$)
   mktime($;$$)
   mode_bits($;$)
   module_define($;$$$)
   module_lookup($;$$)
   module_lookup_closure($;$)
   module_reverse_lookup($;$$)
   module_transformer($;$)
   modules_prehistory
   modulo($;$$)
   must_strdup($;$)
   nconc2last($;$)
   negative_p($;$)
   newline
   nice($;$)
   nil_car($;$)
   nil_cdr($;$)
   nil_cons($;$$)
   nil_eq($;$$)
   noop($;$)
   normbig($;$)
   not($;$)
   ntohl($;$)
   ntohs($;$)
   null($;$)
   null_p($;$)
   num2dbl($;$$)
   num_eq_p($;$$)
   number_p($;$)
   number_to_string($;$$)
   object_address($;$)
   object_properties($;$)
   object_property($;$$)
   object_to_string($;$$)
   odd_p($;$)
   open($;$$$)
   open_fdes($;$$$)
   open_file($;$$)
   open_input_string($;$)
   open_output_string($;)
   open_pipe($;$$)
   opendir($;$)
   operator_p($;$)
   output_port_p($;$)
   pair_p($;$)
   parse_path($;$$)
   pause($;)
   peek_char($;$)
   permanent_object($;$)
   pipe($;)
   port_closed_p($;$)
   port_column($;$)
   port_filename($;$)
   port_for_each($;$)
   port_line($;$)
   port_mode($;$)
   port_p($;$)
   port_revealed($;$)
   port_with_print_state($;$$)
   ports_prehistory
   positive_p($;$)
   primitive_eval($;$)
   primitive_eval_x($;$)
   primitive_exit($;$)
   primitive_generic_generic($;$)
   primitive_load($;$)
   primitive_load_path($;$)
   primitive_make_property($;$)
   primitive_move_to_fdes($;$$)
   primitive_property_del_x($;$$)
   primitive_property_ref($;$$)
   primitive_property_set_x($;$$$)
   prin1($$$)
   print_options($;$)
   print_port_mode($$)
   procedure($;$)
   procedure_documentation($;$)
   procedure_environment($;$)
   procedure_name($;$)
   procedure_p($;$)
   procedure_properties($;$)
   procedure_property($;$$)
   procedure_source($;$)
   procedure_with_setter_p($;$)
   product($;$$)
   program_arguments($;)
   promise_p($;$)
   protect_object($;$)
   pseudolong($;$)
   pt_member($;$)
   pt_size($;)
   putenv($;$)
   puts($$)
   quotient($;$$)
   ra2contig($;$$)
   ra_difference($;$$)
   ra_divide($;$$)
   ra_eqp($;$$)
   ra_greqp($;$$)
   ra_grp($;$$)
   ra_leqp($;$$)
   ra_lessp($;$$)
   ra_matchp($;$$)
   ra_product($;$$)
   ra_set_contp($)
   ra_sum($;$$)
   raequal($;$$)
   raise($;$)
   random($;$$)
   random_exp($;$)
   random_hollow_sphere_x($;$$)
   random_normal($;$)
   random_normal_vector_x($;$$)
   random_solid_sphere_x($;$$)
   random_uniform($;$)
   read($;$)
   read_0str($;$)
   read_and_eval_x($;$)
   read_char($;$)
   read_hash_extend($;$$)
   read_line($;$)
   read_only_string_p($;$)
   read_options($;$)
   readdir($;$)
   readlink($;$)
   ready_p($;)
   real_equalp($;$$)
   real_p($;$)
   real_part($;$)
   recv($;$$$)
   recvfrom($;$$$$$)
   redirect_port($;$$)
   registered_modules($;)
   release_arbiter($;$)
   remainder($;$$)
   remember($)
   remember_upto_here_1($)
   remember_upto_here_2($$)
   remove_from_port_table($)
   remove_hook_x($;$$)
   rename($;$$)
   report_stack_overflow
   reset_hook_x($;$)
   resolve_module($;$)
   restore_signals($;)
   revealed_count($;$)
   reverse($;$)
   reverse_lookup($;$$)
   reverse_x($;$$)
   rewinddir($;$)
   rmdir($;$)
   round($;$)
   run_asyncs($;$)
   run_hook($;$$)
   scm2bool($;$)
   scm2chars($;$$)
   scm2double($;$)
   scm2int($;$)
   scm2long($;$)
   scm2ulong($;$)
   search_path($;$$$)
   seed_to_random_state($;$)
   seek($;$$$)
   select($;$$$$$)
   send($;$$$)
   sendto($;$$$$$)
   set_car_x($;$$)
   set_cdr_x($;$$)
   set_current_error_port($;$)
   set_current_input_port($;$)
   set_current_module($;$)
   set_current_output_port($;$)
   set_object_procedure_x($;$$)
   set_object_properties_x($;$$)
   set_object_property_x($;$$$)
   set_port_column_x($;$$)
   set_port_filename_x($;$$)
   set_port_line_x($;$$)
   set_port_revealed_x($;$$)
   set_procedure_properties_x($;$$)
   set_procedure_property_x($;$$$)
   set_source_properties_x($;$$)
   set_source_property_x($;$$$)
   set_struct_vtable_name_x($;$$)
   set_switch_rate($;$)
   set_tick_rate($;$)
   setbuf0($;$)
   setegid($;$)
   seteuid($;$)
   setgid($;$)
   setgrent($;$)
   sethost($;$)
   sethostname($;$)
   setlocale($;$$)
   setnet($;$)
   setpgid($;$$)
   setpriority($;$$$)
   setproto($;$)
   setpwent($;$)
   setserv($;$)
   setsid($;)
   setsockopt($;$$$$)
   setter($;$)
   setuid($;$)
   setvbuf($;$$$)
   shap2ra($;$$)
   shared_array_increments($;$)
   shared_array_offset($;$)
   shared_array_root($;$)
   shell_usage($$)
   shutdown($;$$)
   sigaction($;$$$)
   signal_condition_variable($;$)
   simple_format($;$$$)
   sleep($;$)
   sloppy_assoc($;$$)
   sloppy_assq($;$$)
   sloppy_assv($;$$)
   sloppy_member($;$$)
   sloppy_memq($;$$)
   sloppy_memv($;$$)
   slot_bound_p($;$$)
   slot_bound_using_class_p($;$$$)
   slot_exists_using_class_p($;$$$)
   slot_ref($;$$)
   slot_ref_using_class($;$$$)
   slot_set_using_class_x($;$$$$)
   slot_set_x($;$$$)
   slots_exists_p($;$$)
   smob_prehistory
   socket($;$$$)
   socketpair($;$$$)
   sort($;$$)
   sort_list($;$$)
   sort_list_x($;$$)
   sort_x($;$$)
   sorted_p($;$$)
   source_properties($;$)
   source_property($;$$)
   srcprops_to_plist($;$)
   stable_sort($;$$)
   stable_sort_x($;$$)
   stack_id($;$)
   stack_length($;$)
   stack_p($;$)
   stack_ref($;$$)
   stack_report
   standard_eval_closure($;$)
   standard_interface_eval_closure($;$)
   start_stack($;$$$)
   stat($;$)
   status_exit_val($;$)
   status_stop_sig($;$)
   status_term_sig($;$)
   str02scm($;$)
   strerror($;$)
   strftime($;$$)
   string($;$)
   string_append($;$)
   string_capitalize($;$)
   string_capitalize_x($;$)
   string_ci_equal_p($;$$)
   string_ci_geq_p($;$$)
   string_ci_gr_p($;$$)
   string_ci_leq_p($;$$)
   string_ci_less_p($;$$)
   string_ci_to_symbol($;$)
   string_copy($;$)
   string_downcase($;$)
   string_downcase_x($;$)
   string_equal_p($;$$)
   string_fill_x($;$$)
   string_geq_p($;$$)
   string_gr_p($;$$)
   string_index($;$$$$)
   string_length($;$)
   string_leq_p($;$$)
   string_less_p($;$$)
   string_null_p($;$)
   string_p($;$)
   string_ref($;$$)
   string_rindex($;$$$$)
   string_set_x($;$$$)
   string_split($;$$)
   string_to_list($;$)
   string_to_number($;$$)
   string_to_obarray_symbol($;$$$)
   string_to_symbol($;$)
   string_upcase($;$)
   string_upcase_x($;$)
   strport_to_string($;$)
   strprint_obj($;$)
   strptime($;$$)
   struct_create_handle($;$)
   struct_p($;$)
   struct_prehistory
   struct_ref($;$$)
   struct_set_x($;$$$)
   struct_vtable($;$)
   struct_vtable_name($;$)
   struct_vtable_p($;$)
   struct_vtable_tag($;$)
   subr_p($;$)
   substring($;$$$)
   substring_fill_x($;$$$$)
   sum($;$$)
   swap_fluids($$)
   swap_fluids_reverse($$)
   switch
   sym2ovcell($;$$)
   sym2ovcell_soft($;$$)
   sym2var($;$$$)
   sym2vcell($;$$$)
   symbol2scm($;$)
   symbol_binding($;$$)
   symbol_bound_p($;$$)
   symbol_fref($;$)
   symbol_fset_x($;$$)
   symbol_hash($;$)
   symbol_interned_p($;$$)
   symbol_p($;$)
   symbol_pref($;$)
   symbol_pset_x($;$$)
   symbol_set_x($;$$$)
   symbol_to_string($;$)
   symbol_value0($;$)
   symbols_prehistory
   symlink($;$$)
   sync($;)
   sys_allocate_instance($;$$)
   sys_atan2($;$$)
   sys_compute_applicable_methods($;$$)
   sys_compute_slots($;$)
   sys_expt($;$$)
   sys_fast_slot_ref($;$$)
   sys_fast_slot_set_x($;$$$)
   sys_inherit_magic_x($;$$)
   sys_initialize_object($;$$)
   sys_invalidate_class($;$)
   sys_invalidate_method_cache_x($;$)
   sys_library_dir($;)
   sys_make_void_port($;$)
   sys_method_more_specific_p($;$$$)
   sys_modify_class($;$$)
   sys_modify_instance($;$$)
   sys_package_data_dir($;)
   sys_prep_layout_x($;$)
   sys_search_load_path($;$)
   sys_set_object_setter_x($;$$)
   sys_site_dir($;)
   sys_tag_body($;$)
   sysintern($;$$)
   sysintern0($;$)
   sysintern0_no_module_lookup($;$)
   system($;$)
   system_async($;$)
   system_async_mark($;$)
   system_module_env_p($;$)
   t_arrayo_list($;$)
   tables_prehistory
   take0str($;$)
   tcgetpgrp($;$)
   tcsetpgrp($;$$)
   the_root_module($;)
   threads_make_mutex($;)
   threads_mark_stacks
   threads_monitor($;)
   throw($;$$)
   thunk_p($;$)
   times($;)
   tmpnam($;)
   top_level_env($;$)
   transpose_array($;$$)
   trunc($;$)
   truncate($;$)
   truncate_file($;$$)
   try_arbiter($;$)
   ttyname($;$)
   tzset($;)
   umask($;$)
   uname($;)
   ungetc($$)
   ungets($$$)
   unhash_name($;$)
   uniform_array_read_x($;$$$$)
   uniform_array_write($;$$$$)
   uniform_vector_length($;$)
   uniform_vector_ref($;$$)
   unintern_symbol($;$$)
   unlock_mutex($;$)
   unmask_signals($;)
   unmemocar($;$$)
   unmemocopy($;$$)
   unmemoize($;$)
   unprotect_object($;$)
   unread_char($;$$)
   unread_string($;$$)
   usleep($;$)
   utime($;$$$)
   valid_object_procedure_p($;$)
   valid_oport_value_p($;$)
   values($;$)
   variable_bound_p($;$)
   variable_p($;$)
   variable_ref($;$)
   variable_set_name_hint($;$$)
   variable_set_x($;$$)
   vector($;$)
   vector_equal_p($;$$)
   vector_fill_x($;$$)
   vector_length($;$)
   vector_p($;$)
   vector_ref($;$$)
   vector_set_length_x($;$$)
   vector_set_x($;$$$)
   vector_to_list($;$)
   version($;)
   void_port($;$)
   wait_condition_variable($;$$)
   waitpid($;$$)
   weak_key_hash_table_p($;$)
   weak_value_hash_table_p($;$)
   weak_vector($;$)
   weak_vector_p($;$)
   weaks_prehistory
   with_fluids($;$$$)
   with_traps($;$)
   write($)
   write_char($;$$)
   write_line($;$$)
   yield($;)
   zero_p($;$)

=cut

=pod

=head1 AUTHOR

Sam Tregar, sam@tregar.com

Co-maintained by Matt S Trout, perl-stuff@trout.me.uk

=head1 SEE ALSO

Inline

=head1 LICENSE

Guile : A Perl binding to the GNU Guile Interpreter.
Copyright (C) 2001-2004 Sam Tregar (sam@tregar.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=cut
