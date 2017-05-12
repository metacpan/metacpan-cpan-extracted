#line 1
package Module::CPANfile;
use strict;
use warnings;
use Cwd;
use Carp ();
use Module::CPANfile::Environment ();
use Module::CPANfile::Result;

our $VERSION = '0.9034';

sub new {
    my($class, $file) = @_;
    bless {}, $class;
}

sub load {
    my($proto, $file) = @_;
    my $self = ref $proto ? $proto : $proto->new;
    $self->{file} = $file || "cpanfile";
    $self->parse;
    $self;
}

sub save {
    my($self, $path) = @_;

    open my $out, ">", $path or die "$path: $!";
    print {$out} $self->to_string;
}

sub parse {
    my $self = shift;

    my $file = Cwd::abs_path($self->{file});
    $self->{result} = Module::CPANfile::Environment::parse($file) or die $@;
}

sub from_prereqs {
    my($proto, $prereqs) = @_;

    my $self = $proto->new;
    $self->{result} = Module::CPANfile::Result->from_prereqs($prereqs);

    $self;
}

sub features {
    my $self = shift;
    map $self->feature($_), keys %{$self->{result}{features}};
}

sub feature {
    my($self, $identifier) = @_;

    my $data = $self->{result}{features}{$identifier}
      or Carp::croak("Unknown feature '$identifier'");

    require CPAN::Meta::Feature;
    CPAN::Meta::Feature->new($data->{identifier}, {
        description => $data->{description},
        prereqs => $data->{spec},
    });
}

sub prereqs { shift->prereq }

sub prereqs_with {
    my($self, @feature_identifiers) = @_;

    my $prereqs = $self->prereqs;
    my @others = map { $self->feature($_)->prereqs } @feature_identifiers;

    $prereqs->with_merged_prereqs(\@others);
}

sub prereq {
    my $self = shift;
    require CPAN::Meta::Prereqs;
    CPAN::Meta::Prereqs->new($self->prereq_specs);
}

sub prereq_specs {
    my $self = shift;
    $self->{result}{spec};
}

sub merge_meta {
    my($self, $file, $version) = @_;

    require CPAN::Meta;

    $version ||= $file =~ /\.yml$/ ? '1.4' : '2';

    my $prereq = $self->prereqs;

    my $meta = CPAN::Meta->load_file($file);
    my $prereqs_hash = $prereq->with_merged_prereqs($meta->effective_prereqs)->as_string_hash;
    my $struct = { %{$meta->as_struct}, prereqs => $prereqs_hash };

    CPAN::Meta->new($struct)->save($file, { version => $version });
}

sub _dump {
    my $str = shift;
    require Data::Dumper;
    chomp(my $value = Data::Dumper->new([$str])->Terse(1)->Dump);
    $value;
}

sub to_string {
    my($self, $include_empty) = @_;

    my $prereqs = $self->{result}{spec};

    my $code = '';
    $code .= $self->_dump_prereqs($self->{result}{spec}, $include_empty);

    for my $feature (values %{$self->{result}{features}}) {
        $code .= sprintf "feature %s, %s => sub {\n", _dump($feature->{identifier}), _dump($feature->{description});
        $code .= $self->_dump_prereqs($feature->{spec}, $include_empty, 4);
        $code .= "}\n\n";
    }

    $code =~ s/\n+$/\n/s;
    $code;
}

sub _dump_prereqs {
    my($self, $prereqs, $include_empty, $base_indent) = @_;

    my $code = '';
    for my $phase (qw(runtime configure build test develop)) {
        my $indent = $phase eq 'runtime' ? '' : '    ';
        $indent = (' ' x ($base_indent || 0)) . $indent;

        my($phase_code, $requirements);
        $phase_code .= "on $phase => sub {\n" unless $phase eq 'runtime';

        for my $type (qw(requires recommends suggests conflicts)) {
            for my $mod (sort keys %{$prereqs->{$phase}{$type}}) {
                my $ver = $prereqs->{$phase}{$type}{$mod};
                $phase_code .= $ver eq '0'
                             ? "${indent}$type '$mod';\n"
                             : "${indent}$type '$mod', '$ver';\n";
                $requirements++;
            }
        }

        $phase_code .= "\n" unless $requirements;
        $phase_code .= "};\n" unless $phase eq 'runtime';

        $code .= $phase_code . "\n" if $requirements or $include_empty;
    }

    $code =~ s/\n+$/\n/s;
    $code;
}

1;

__END__

#line 283
