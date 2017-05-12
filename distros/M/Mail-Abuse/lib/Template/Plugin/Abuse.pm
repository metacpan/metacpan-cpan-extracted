package Template::Plugin::Abuse;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.00';

use base qw(Template::Plugin);

use PerlIO::gzip;
use IO::File;
use File::Spec;
use NetAddr::IP;
use Template::Plugin;
use Template::Exception;

use Storable qw/fd_retrieve/;

sub dereference
{
    my $ref = shift;

    $ref = $$ref while ref($ref) eq 'SCALAR';
    $ref;
}

sub new
{ 
    my $class	= shift;
    my $context	= shift;
    my $args	= shift || {};

    $context->stash->set('deref' => \&dereference);

    $context->throw('Abuse.pathmissing', 'Must specify path')
	unless $args->{path};

    my $self = bless
    {
	_CONTEXT	=> $context,
	_ARGS		=> $args,
	path		=> $args->{path},
    }, $class;

    return $self;
}

sub fetch
{
    my $self = shift;
    my $arg = shift;

    my $fh = new IO::File;
    my $rep;
    my $data;
    my $ctx = $self->{_CONTEXT};

    return unless $arg->{id};

    $ctx->throw('Abuse.invalid',
		'Invalid Abuse report id')
	unless $arg->{id} =~ m!^[-/A-Za-z0-9]+(.gz)?$!;

    my $path = File::Spec->catfile($self->{path}, $arg->{id});

    $ctx->throw('Abuse.notfound',
		'Abuse report id not found')
	unless -f $path or -f ($path .= '.gz');

    $ctx->throw('Abuse.open',
		"Problem opening Abuse report: $!")
	unless $fh->open($path, "<:gzip(autopop)");

    if ($arg->{mode} =~ /^plain/)
    {
	local $/ = undef;
	$rep = <$fh>;
    }
    else
    {
	eval { $rep = fd_retrieve($fh) };
    }

    close $fh;

    return $rep;
}

42;

__END__

=head1 NAME

Template::Plugin::Abuse - A plugin for accessing abuse complaints

=head1 SYNOPSIS

    [% USE sample = Abuse ( path = dir ); %]
    
    ... fun with the abuse report ...

=head1 DESCRIPTION

This plugin provides access to abuse reports processed and stored by
L<Mail::Abuse>'s L<Mail::Abuse::Processor::Store>. This plugin
supports on the fly uncompressing using L<PerlIO::gzip> of the stored
abuse report if it has been compressed with L<gzip> and its name ends
in ".gz".

At time of C<USE>, the attribute C<path> must be used to tell the
plugin where to look for abuse reports. This path will be used to
compose the full filename to load the abuse report from.

Note that all the modules used in the processing of an abuse report
must be loaded prior to fetching abuse reports. Currently, there is no
easy way to do so automatically, so you need to do that yourself,
probably either in the L<Template::Toolkit> driver or in your Apache
setup, if using this module for generating web content.

The following methods are supported:

=over

=item B<fetch( id = report mode = store-mode )>

Fetches the abuse report from stable storage and returns either an
object with the same accessors/values for L<Template::Toolkit> use or
a scalar with the body of the abuse report, depending on the B<mode>
requested. B<id> identifies the abuse report to fetch. B<mode> is the
mode used by L<Mail::Abuse::Processor::Store> when storing the abuse
report.

=back

Many of the elements stored into a L<Mail::Abuse::Report> object are
references. To help with this, the plugin exports the B<deref()>
method, that will dereference references to scalars automatically.

Exceptions are thrown to indicate unusual errors or situations. The
possible exceptions are:

=over

=item B<Abuse.pathmissing>

Thrown when no C<path> attribute is specified to C<USE>.

=item B<Abuse.invalid>

Thrown when the given C<id> to C<fetch> contains unusual or
potentially unsafe characters.

=item B<Abuse.notfound>

This exception is thrown when the identified abuse report cannot be
found.

=item B<Abuse.open>

A problem opening the stored abuse report has been detected.

=back

=head2 EXPORT

None by default.

=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.23 with options

  -A
	-C
	-X
	-c
	-n
	Template::Plugin::Authenticator
	-v
	1.00
	--skip-autoloader

=back

=head1 SEE ALSO

Template::Toolkit, Mail::Abuse, PerlIO::gzip, gzip.

=head1 AUTHOR

Luis E. Muñoz E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
