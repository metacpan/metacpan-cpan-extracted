#-----------------------------------------------------------------
# MOSES::MOBY::Service::ServiceBase
# Author: Martin Senger <martin.senger@gmail.com>,
#         Edward Kawas <edward.kawas@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: ServiceBase.pm,v 1.4 2008/04/29 19:43:44 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Service::ServiceBase;

use MOSES::MOBY::Base;
use base qw( MOSES::MOBY::Base );
use SOAP::Lite;
use MOSES::MOBY::Package;

use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# prepare_output
#-----------------------------------------------------------------
#sub prepare_output {
#    my ($self, $in_package) = @_;
#    my ($out_package) = new MOSES::MOBY::Package;
#    foreach my $job (@{ $in_package->jobs }) {
#	my $response_job = new MOSES::MOBY::Job (jid => $job->jid);
#	$response_job->_context ($out_package);
#	print $response_job;
#	$out_package->add_jobs ($response_job);
#    }
#    return $out_package;
#}

#-----------------------------------------------------------------
# process_all
#-----------------------------------------------------------------
sub process_all {
    my ($self, $in_package, $out_package) = @_;

    foreach my $job (@{ $in_package->jobs }) {
	$self->process_it ($job, $out_package->job_by_id ($job->jid), $out_package);
    }
}

#-----------------------------------------------------------------
# process_it
#-----------------------------------------------------------------
sub process_it {
    my ($self, $request, $response, $context) = @_;
}

#-----------------------------------------------------------------
# finish_output
#-----------------------------------------------------------------
sub finish_output {
    my ($self, $out_package) = @_;
    return SOAP::Data->type
	('base64' => $out_package->toXMLdocument->toString (1));    
}

#-----------------------------------------------------------------
# as_uni_string
#-----------------------------------------------------------------
use MOSES::MOBY::Data::String;
use Unicode::String;

sub as_uni_string {
    my ($self, $value) = @_;
    return new MOSES::MOBY::Data::String (Unicode::String::latin1 ($value));
}

#-----------------------------------------------------------------
# create_parser
#    my $parser = $self->create_parser
#	( lowestKnownDataTypes => { language => 'Regex' },
#	  loadDataTypes        => [ qw( Regex simple_key_value_pair ) ] );
#-----------------------------------------------------------------
sub create_parser {
    my ($self, @args) = @_;
    my %args =
	( lowestKnownDataTypes => {},
	  loadDataTypes        => [],
	  @args );
	    
    $self->throw ('Cannot find a configuration option CACHEDIR. ' .
		  'This should point to a local cache of BioMoby registry.')
	unless $MOBYCFG::CACHEDIR;

    my $generator = MOSES::MOBY::Generators::GenTypes->new
	( cachedir => $MOBYCFG::CACHEDIR,
	  registry => ($MOBYCFG::REGISTRY || ''),
	  );
    $generator->load ( $args{loadDataTypes} );
    return MOSES::MOBY::Parser->new
	( lowestKnownDataTypes => $args{lowestKnownDataTypes},
	  cachedir             => $MOBYCFG::CACHEDIR,
	  registry             => ($MOBYCFG::REGISTRY || ''),
	  generator            => $generator,
	  );
}

#-----------------------------------------------------------------
# log_request
#
# should be called when a request from a client comes; it returns
# information about the current call (request) that can be used in a
# log entry
#-----------------------------------------------------------------

my @ENV_TO_REPORT =
    ('REMOTE_ADDR', 'HTTP_USER_AGENT', 'CONTENT_LENGTH', 'HTTP_SOAPACTION');

sub log_request {
    my ($self) = shift;

    my @buf;
    foreach my $elem (@ENV_TO_REPORT) {
	push (@buf, "$elem: $ENV{$elem}") if exists $ENV{$elem};
    }
    return join (", ", @buf);
}

1;
__END__

=head1 NAME

MOSES::MOBY::ServiceBase - a super-class for all BioMoby services

=head1 SYNOPSIS

 use base qw( MOSES::MOBY::ServiceBase )
 
=head1 DESCRIPTION

=head1 SUBROUTINES

=head2 prepare_output

Return a package (C<MOSES::MOBY::Package>) that has the same number of jobs,
with the same ids, as the given input (again an C<MOSES::MOBY::Package>).
Otherwise the returned package is empty.

Usually, there is no need to override this method. It is called
by a service skeleton, once an input XML is parsed and before a
service implementation class is called to process it.

An input argument (type C<MOSES::MOBY::Package> contains all data coming from
a client.

It throws an exception if input data package is corrupted.

=head2 process_all

A high-level processing, dealing with all I<jobs> in the same time. It
takes a full input package and for each its individual job it calls a
subroutine C<process_it>.

Override this method if you need access to all jobs in the same
time. Otherwise (a usual case) override the C<process_it> that deals
with a job in time (a processessig on the job level).

There are two (positional) arguments (both of type C<MOSES::MOBY::Package>):

The first one contains all data coming from a client (a requset), the
second is an (almost) empty package that has to be filled, and that
later will go back to the same client (a response). So far, the output
package has already the ame number of jobs as the input package, and
the jobs have already the same IDs.

It does not throw any exception on its own but it calls one or more
times (depending on the number of jobs in the input package) the
C<process_it> and that baby can throw an exception.

=head2 process_it

A job-level processing: B<This is the main method to be overriden by a
service provider!>. Here all the business logic belongs to.

This method is called once for each I<job> in a client request. A
I<job> is a BioMoby query (in a client request), or a result of one
query (in a service response). There can be more queries (jobs) in one
network request to a BioMoby service. If a network request contains
more jobs, also the corresponding service response must contain the
same number of jobs.

Note that here, in C<MOSES::MOBY::Service::ServiceBase>, this method does
nothing. Which means it leaves the output job empty, as it was given
here (having only its job's ID filled in). Consequence is that if you
do not override this method in a sub-class, the client will get back
the same number of jobs as her request had, but they will be
empty. Which may be good just for testing but not really what a client
expects (I guess).

There are three mandatory arguments:

=over

=item I<request>

An argument of type C<MOSES::MOBY::Job> contain data coming from one client's
job

=item I<response>

An argument of type C<MOSES::MOBY::Job> is an empty job (except its ID that
is already filled in - because it must correspond with the same ID in
the 'input-job'). The task of this method is to fill it with a
response.

=item I<context>

An argument of type C<MOSES::MOBY::Package> is a package that will be, at the
end, delivered to the client; it is here not to be filled - that is
taken care of by some other methods - but you may use it to see how
other (previous) jobs have been made, and also to add things to the
package envelope (e.g. service notes).

=over

You are free to throw an exception (TBD: example here). However, if
you do so the complete processing of the whole client request is
considered failed. After such exception the client will not get any
data back (only an error message).

If you wish just to indicate that only this particular job failed you
have to add an exception to the C<context> parameter. (TBD: example
here) - and do not throw any exception.

=head2 finish_output

Finalize (and return) an already filled package (C<MOSES::MOBY::Package>) in
order to be sent as a web service response. The implementation depends
on the underlying message protocol (such as SOAP). Having it separated
here shields the service providers - but you can still override this
method and do something fancy instead. Just remember: whatever this
method returns it will be sent back to the client.

An input argument type C<MOBY:;package>) contains a response.

=head2 as_uni_string

Convert given $value (the only argument) into Unicode and wrap it as a
BioMoby string (type MOSES::MOBY::Data::String).

=head2 create_parser

 # create_parser:
 #    my $parser = $self->create_parser
 #	( lowestKnownDataTypes => { language => 'Regex' },
 #	  loadDataTypes        => [ qw( Regex simple_key_value_pair ) ] );

=head2 log_request

 # should be called when a request from a client comes; it returns
 # information about the current call (request) that can be used in a
 # log entry

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

Copyright (c) 2006 Martin Senger, Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=cut

