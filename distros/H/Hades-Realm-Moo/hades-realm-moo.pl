use Hades;
Hades->run({
	eval => q`
		Hades::Realm::Moo base Hades::Realm::OO {
			build_as_role :a {
				$params[0]->use(q|Moo::Role|);
				$params[0]->use(q|MooX::Private::Attribute|);
				$params[0]->use(sprintf q|Types::Standard qw/%s/|, join(' ', keys %{$self->meta->{$self->current_class}->{types}}));
			}
			build_as_class :a {
				$params[0]->use(q|Moo|);
				$params[0]->use(q|MooX::Private::Attribute|);
				$params[0]->use(sprintf q|Types::Standard qw/%s/|, join(' ', keys %{$self->meta->{$self->current_class}->{types}}));
			}
			build_has $meta :t(HashRef) { 
				$meta->{is} ||= '"rw"';
				my $attributes = join ', ', map {
					($meta->{$_} ? (sprintf "%s => %s", $_, $meta->{$_}) : ())
				} qw/is required clearer predicate isa private/;
				$attributes .= ', ' .  join ', ', map {
					$meta->{$_}
						? ($_ ne 'default' and $meta->{$_} =~ m/^[\w\d]+$/)
							? (sprintf '%s => "%s"', $_, $meta->{$_})
							: (sprintf "%s => sub { %s }", $_, $meta->{$_})
						: ()
				} qw/default coerce trigger/;
				my $name = $meta->{has};
				my $code = qq{
					has $name => ( $attributes );};
				return $code;
			}
		}
	`,
	lib => 'lib',
	tlib => 't'
});

