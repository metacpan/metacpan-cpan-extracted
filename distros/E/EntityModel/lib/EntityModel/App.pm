package EntityModel::App;
{
  $EntityModel::App::VERSION = '0.102';
}
use EntityModel::Class {
	model	=> { type => 'EntityModel::Model' },
};
use EntityModel;
use EntityModel::Definition::JSON;
use EntityModel::Definition::XML;
use Module::Load;

=head1 NAME

EntityModel::App - interface to L<EntityModel> admin application

=head1 VERSION

version 0.102

=head1 SYNOPSIS

see L<EntityModel>.

=head1 DESCRIPTION

see L<EntityModel>.


=head1 METHODS

=cut

=head2 show_model

Display information about the current model.

=cut

sub show_model {
	my $self = shift;
	my $model = $self->model;
	$self->show(
		model_info => {
			model => $model,
			name => $model->name,
			entity => $model->entity,
			plugin => $model->plugin,
		}
	);
}

=head2 show_model_info

=cut

sub show_model_info {
	my ($self, $info) = @_;
	print "Model " . $info->{model}->name . " has " . $info->{entity}->count . " entities:\n";
	printf " * %s has fields %s\n", $_->name, join ',', map $_->name, $_->field->list for $info->{entity}->list;
	foreach my $plugin ($info->{plugin}->list) {
		$self->show(plugin_info => { plugin => $plugin });
	}
}

=head2 show_plugin_info

=cut

sub show_plugin_info {
	my ($self, $info) = @_;
	my $plugin = $info->{plugin};
	print "Plugin " . ref($plugin) . ":\n";
	foreach my $site ($plugin->site->list) {
		print  " * Site " . $site->host . ":\n";
		printf "   * Template: %s\n", ($site->template // 'undef');
#			try { printf "   * Layout:   %s => %s\n", $_->section, $_->wrapper for $site->layout->list; } catch { warn "$_"; };
		printf "   * Page:     %s for %s\n", $_->name, $_->path for $site->page->list;
	}
}

=head2 show

=cut

sub show {
	my $self = shift;
	my $k = shift;
	$self->${\"show_$k"}(@_);
	return $self;
}

sub create_model {
	my $self = shift;
	die "have a model already" if $self->model;

# Bring in any extra plugins we might have available
# FIXME should be dynamic
	my $model = EntityModel->new;
	foreach my $type (qw(Web)) {
		try {
			my $class = "EntityModel::$type";
			load($class);
			my $instance = $class->new;
			$model->add_plugin($instance);
		} catch {
			warn "Failed to load $type - $_";
		};
	}
	$self->model($model);
	$model;
}

sub load_model {
	my $self = shift;
	my $file = shift;
	my $model = $self->model || $self->create_model;

	if($file =~ /\.json$/) {
		$model->load_from(
			JSON => { file => $file }
		);
	} elsif($file =~ /\.xml$/) {
		$model->load_from(
			XML => { file => $file }
		);
	} else {
		die "Unknown extension, expected .json or .xml: - $file\n";
	}
	$self->model($model);
	return $self;
}

{# %arg_mapping
my %arg_mapping = (
	'-f' => sub {
		my $self = shift;
		my %args = @_;
		my $file = shift @{$args{args}};
		$self->load_model($file);
		return $self;
	},

	'list' => sub {
		my $self = shift;
		$self->show_model;
	},

	'export' => sub {
		my $self = shift;
		my $def = EntityModel::Definition::JSON->new;
		$def->model($self->model);
		print $def->save(string => '');
	},

	'merge' => sub {
		my $self = shift;
		my %args = @_;
		my $input = shift @{$args{args}};

		my $name = $self->model->name;
		if($input eq '-') {
			$self->load_model(*STDIN);
		} else {
			$self->load_model($input);
		}

		# Reset name if we had one
		$self->model->name($name) if $name;
		my $def = EntityModel::Definition::JSON->new;
		$def->model($self->model);
		print "Merged with $input\n";
	},

	ui => sub {
		my $self = shift;
		print "entitymodel> ";
		COMMAND:
		while(my $line = <STDIN>) {
			chomp $line;
			my ($cmd, @args) = split ' ', $line;
			last COMMAND if $cmd eq 'quit';

			try {
				if($cmd eq 'read') {
					$self->model(undef);
					$cmd = '-f';
				}
				$self->from_argv($cmd, @args);
			} catch {
				warn "Failed to run [$cmd" . (@args ? " @args" : "") . "]: $_";
			};
		} continue {
			print "entitymodel> ";
		}
		print "\n";
	}
);

=head2 from_argv

=cut

sub from_argv {
	my $self = shift;
	my @argv = @_;

	ARG:
	while(@argv) {
		my $code = $self->code_for_entry(shift @argv);
		$self->$code(args => \@argv);
	}
	$self;
}

sub code_for_entry {
	my ($self, $k) = @_;
	if(my $code = $arg_mapping{$k}) {
		return $code;
	} else {
		die "Unknown parameter '$k'";
	}
}

}# %arg_mapping

__PACKAGE__->new->from_argv(@ARGV) unless caller;

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
