#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 10;
#use Test::More 'no_plan';

use Frost::Asylum;

#	from Moose-0.87/t/000_recipes/moose_cookbook_basics_recipe6.t

# =begin testing SETUP
{
	package Document::Page;
#	use Moose;
	use Frost;

	has 'body' => ( is => 'rw', isa => 'Str', default => sub {''} );

	sub create {
			my $self = shift;
			$self->open_page;
			inner();
			$self->close_page;
	}

	sub append_body {
			my ( $self, $appendage ) = @_;
			$self->body( $self->body . $appendage );
	}

	sub open_page	{ (shift)->append_body('<page>') }
	sub close_page { (shift)->append_body('</page>') }

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Document::PageWithHeadersAndFooters;
	use Moose;

	extends 'Document::Page';

	augment 'create' => sub {
			my $self = shift;
			$self->create_header;
			inner();
			$self->create_footer;
	};

	sub create_header { (shift)->append_body('<header/>') }
	sub create_footer { (shift)->append_body('<footer/>') }

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package TPSReport;
	use Moose;

	extends 'Document::PageWithHeadersAndFooters';

	augment 'create' => sub {
			my $self = shift;
			$self->create_tps_report;
			inner();
	};

	sub create_tps_report {
			(shift)->append_body('<report type="tps"/>');
	}

#	# <page><header/><report type="tps"/><footer/></page>
#	my $report_xml = TPSReport->new->create;

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

# =begin testing
{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	#	my $tps_report = TPSReport->new;
	my $tps_report = TPSReport->new ( asylum => $ASYL, id => 'Report' );
	isa_ok( $tps_report, 'TPSReport', 'tps_report' );
	isa_ok( $tps_report, 'Frost::Locum', 'tps_report' );

	is(
			$tps_report->create,
			q{<page><header/><report type="tps"/><footer/></page>},
			'... got the right TPS report'
	);

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $tps_report = TPSReport->new ( asylum => $ASYL, id => 'Report' );
	isa_ok( $tps_report, 'TPSReport', 'tps_report' );
	isa_ok( $tps_report, 'Frost::Locum', 'tps_report' );

	is(
			$tps_report->body,
			q{<page><header/><report type="tps"/><footer/></page>},
			'... got the right TPS report'
	);

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
