#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Future::Workflow::Pipeline 0.02;
class Future::Workflow::Pipeline;

use Carp;

use Future::AsyncAwait;

=head1 NAME

C<Future::Workflow::Pipeline> - a pipeline of processing stages

=head1 SYNOPSIS

=for highlighter language=perl

   # 1: Make a pipeline
   my $pipeline = Future::Workflow::Pipeline->new;


   # 2: Add some stages to it
 
   # An async stage; e.g. perform an HTTP fetch
   my $ua = Net::Future::HTTP->new;
   $pipeline->append_stage_async( async sub ($url) {
      return await $ua->GET( $url );
   });

   # A synchronous (in-process) stage; e.g. some HTML parsing
   $pipeline->append_stage_sync( sub ($response) {
      my $dom = Mojo::DOM->new( $response->decoded_content );
      return $dom->at('div[id="main"]')->text;
   });

   # A detached (out-of-process/thread) stage; e.g. some silly CPU-intensive task
   $pipeline->append_stage_detached( sub ($text) {
      my $iter = Algorithm::Permute->new([ split m/\s+/, $text ]);

      my $best; my $bestscore;
      while(my @words = $iter->next) {
         my $str = join "\0", @words;
         my $score = md5sum( $str );
         next if defined $bestscore and $score ge $bestscore;

         $best      = $str;
         $bestscore = $score;
      }

      return $best;
   });


   # 3: Give it an output

   # These are alternatives:

   # An asynchronous output
   my $dbh = Database::Async->new( ... );
   $pipeline->set_output_async( async sub ($best) {
      await $dbh->do('INSERT INTO Results VALUES (?)', $best);
   });

   # A synchronous output
   $pipeline->set_output_sync( sub ($best) {
      print "MD5 minimized sort order is:\n";
      print "  $_\n" for split m/\0/, $best;
   });


   # 4: Now start it running on some input values

   foreach my $url (slurp_lines("urls.txt")) {
      await $pipeline->push_input($url);
   }


   # 5: Wait for it all to finish
   await $pipeline->drain;

=head1 DESCRIPTION

Instances of this class implement a "pipeline", a sequence of data-processing
stages. Each stage is represented by a function that is passed a single
argument and should return a result. The pipeline itself stores a function
that will be passed each eventual result.

=head2 Queueing

In front of every stage there exists a queue of pending items. If the first
stage is currently busy when C</push_input> is called, the item is accepted
into its queue instead. Items will be taken from the queue in the order they
were pushed when the stage's work function finishes with prior items.

If the queue between stages is full, then items will remain pending in prior
stages. Ultimately this back-pressure will make its way back to the
C</push_input> method at the beginning of the pipeline.

=cut

=head1 CONSTRUCTOR

   $pipeline = Future::Workflow::Pipeline->new;

The constructor takes no additional parameters.

=cut

field $_output;
field @_stages;

=head1 METHODS

=cut

=head2 set_output

   $pipeline->set_output( $code );

      await $code->( $result );

Sets the destination output for the pipeline. Each completed work item will be
passed to the invoked function, which is expected to return a C<Future>.

=cut

method set_output ( $code )
{
   $_output = $code;
   $_stages[-1]->set_output( $_output ) if @_stages;
}

=head2 set_output_sync

   $pipeline->set_output_sync( $code );

      $code->( $result );

Similar to L</set_output>, where the output function is called synchronously,
returning when it has finished.

=cut

method set_output_sync ( $code )
{
   $self->set_output( async sub ( $result ) { $code->( $result ) } );
}

=head2 append_stage

   $pipeline->append_stage( $code, %args );

      $result = await $code->( $item );

Appends a pipeline stage that is implemented by an asynchronous function. Each
work item will be passed in by invoking the function, and it is expected to
return a C<Future> which will eventually yield the result of that stage.

The following optional named args are recognised:

=over 4

=item concurrent => NUM

Allow this number of outstanding items concurrently.

=item max_queue => NUM

If defined, no more than this number of items can be enqueued. If undefined,
no limit is applied.

This value can be zero, which means that any attempts to push more items will
remain pending until the work function is free to deal with it; i.e. no
queueing will be permitted.

=item on_failure => CODE

   $on_failure->( $f )

Provides a callback event function for handling a failure thrown by the stage
code. If not provided, the default behaviour is to print the failure message
as a warning.

Note that this handler cannot turn a failure into a successful result or
otherwise resume or change behaviour of the pipeline. For error-correction you
will have to handle that inside the stage function code itself. This handler
is purely the last stop of error handling, informing the user of an
otherwise-unhandled error before ignoring it.

=back

=cut

method append_stage ( $code, %args )
{
   my $old_tail = @_stages ? $_stages[-1] : undef;

   push @_stages, my $new_tail = Future::Workflow::Pipeline::_Stage->new(
      code => $code,
      %args,
   );
   $new_tail->set_output( $_output ) if $_output;

   $old_tail->set_output( async sub ( $item ) {
      await $new_tail->push_input( $item );
   } ) if $old_tail;
}

=head2 append_stage_sync

   $pipeline->append_stage_sync( $code, %args );

      $result = $code->( $item );

Similar to L</append_stage>, where the stage function is called synchronously,
returning its result immediately.

Because of this, the C<concurrent> named parameter is not permitted.

=cut

method append_stage_sync ( $code, %args )
{
   defined $args{concurrent} and
      croak "->append_stage_sync does not permit the 'concurrent' parameter";

   return $self->append_stage(
      async sub ( $item ) { return $code->( $item ) },
      %args,
   );
}

=head2 push_input

   await $pipeline->push_input( $item );

Adds a new work item into the pipeline, which will pass through each of the
stages and eventually invoke the output function.

=cut

async method push_input ( $item )
{
   # TODO: this feels like a weird specialcase for no stages
   if( @_stages ) {
      await $_stages[0]->push_input( $item );
   }
   else {
      await $_output->( $item );
   }
}

class Future::Workflow::Pipeline::_Stage :strict(params) {

   use Future;

   field $_code :param;
   field $_output :writer;

   field $_on_failure :param = sub ( $f ) {
      warn "Pipeline stage failed: ", scalar $f->failure;
   };

   # $_concurrent == maximum size of @_work_f
   field $_concurrent :param = 1;
   field @_work_f;

   # $_max_queue == maximum size of @_queue, or undef for unbounded
   field $_max_queue :param = undef;
   field @_queue;

   field @_awaiting_input;

   async method _do ( $item )
   {
      await $_output->( await $_code->( $item ) );
   }

   method _schedule ( $item, $i )
   {
      my $f = $_work_f[$i] = $self->_do( $item );
      $f->on_ready( sub ( $f ) {
         $_on_failure->( $f ) if $f->is_failed;

         if( @_queue ) {
            $self->_schedule( shift @_queue, $i );
            ( shift @_awaiting_input )->done if @_awaiting_input;
         }
         else {
            undef $_work_f[$i];
         }
      } );
   }

   async method push_input ( $item )
   {
      my $i;
      defined $_work_f[$_] or ( $i = $_ ), last
         for 0 .. $_concurrent-1;

      if( defined $i ) {
         $self->_schedule( $item, $i );
      }
      else {
         if( defined $_max_queue and @_queue >= $_max_queue ) {
            # TODO: Maybe we should clone one of the work futures?
            push @_awaiting_input, my $enqueue_f = Future->new;
            await $enqueue_f;
         }
         push @_queue, $item;
      }
   }
}

=head1 UNSOLVED QUESTIONS

=over 4

=item *

Is each work item represented by some object that gets passed around?

Can we store context, maybe in a hash or somesuch, that each stage can inspect
and append more things into? It might be useful to remember at least the
initial URLs by the time we generate the outputs

=item *

Tuning parameters. In particular, being able to at least set overall
concurrency of C<async> and C<detached> stages, the detachment model of the
C<detached> stages (threads vs. forks), inter-stage buffering?

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
