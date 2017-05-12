package BeerDB::Base;
use base qw/Maypole::Model::CDBI/;
use strict;
use warnings;
use Data::Dumper;

# Overide list to add display_columns to cgi  
# Perhaps do this in AsForm?
sub list : Exported {
	use Data::Dumper;
	my ($self, $r) = @_;
	$self->SUPER::list($r);
	my %cols =  map { $_ => 1 } $self->columns, $self->display_columns;
	my @cols = keys %cols;
	$r->template_args->{classmetadata}{cgi} = { $self->to_cgi(@cols) }; 
}

# Override view to make inputs and process form to add to related 
sub view : Exported {
    my ($self, $r, $obj) = @_;
    $self->_croak( "Object method only") unless $obj;

    if ($r->params->{submit}) {
        my @related  = $obj->add_to_from_cgi($r, { required => [$self->related ]});
        if (my $errs = $obj->cgi_update_errors) {
            $r->template_args->{errors} = $errs;
        }
    }

    # Inputs to add to related on the view page
	# Now done on the view template 
	# my %cgi = $self->to_cgi($self->related);
	#$r->template_args->{classmetadata}{cgi} =  \%cgi ;
}


# Template switcheroo bug bit me -- was seeing view page but the view action was never 
# being executed after an edit.
sub do_edit : Exported {
	my ($self, $r) = (shift, shift);
	$self->SUPER::do_edit($r, @_);
	if (my $obj = $r->object) {
		my $url = $r->config->uri_base . "/" . $r->table . "/view/" . $obj->id;
		$r->redirect_request(url => $url);
	}
}

sub metadata: Exported {}
	

1;
