# $Id: ScanDetails.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::ScanDetails;
{
    use Object::InsideOut;
    use XML::LibXML;
    use MetasploitExpress::Parser::Host;
    use MetasploitExpress::Parser::Event;
    use MetasploitExpress::Parser::Task;
    use MetasploitExpress::Parser::Service;
    use MetasploitExpress::Parser::Report;

    my @hosts : Field : Arg(hosts) : Get(hosts) :
        Type(List(MetasploitExpress::Parser::Host));
    my @events : Field : Arg(events) : Get(events) :
        Type(List(MetasploitExpress::Parser::Event));
    my @tasks : Field : Arg(tasks) : Get(tasks) :
        Type(List(MetasploitExpress::Parser::Task));
    my @services : Field : Arg(services) : Get(services) :
        Type(List(MetasploitExpress::Parser::Service));
    my @reports : Field : Arg(reports) : Get(reports) :
        Type(List(MetasploitExpress::Parser::Report));

    sub parse {
        my ( $self, $parser, $doc ) = @_;

        my $xpc = XML::LibXML::XPathContext->new($doc);
        my ( @hosts, @events, @tasks, @reports, @services );

        foreach my $i ( $xpc->findnodes('//MetasploitExpressV3/hosts/host') )
        {
            my $address
                = scalar( @{ $i->getElementsByTagName('address') } ) > 0
                ? @{ $i->getElementsByTagName('address') }[0]->textContent()
                : undef;
            my $address6
                = scalar( @{ $i->getElementsByTagName('address6') } ) > 0
                ? @{ $i->getElementsByTagName('address6') }[0]->textContent()
                : undef;
            my $arch
                = scalar( @{ $i->getElementsByTagName('arch') } ) > 0
                ? @{ $i->getElementsByTagName('arch') }[0]->textContent()
                : undef;
            my $comm
                = scalar( @{ $i->getElementsByTagName('comm') } ) > 0
                ? @{ $i->getElementsByTagName('comm') }[0]->textContent()
                : undef;
            my $comments
                = scalar( @{ $i->getElementsByTagName('comments') } ) > 0
                ? @{ $i->getElementsByTagName('comments') }[0]->textContent()
                : undef;
            my $id
                = scalar( @{ $i->getElementsByTagName('id') } ) > 0
                ? @{ $i->getElementsByTagName('id') }[0]->textContent()
                : undef;
            my $info
                = scalar( @{ $i->getElementsByTagName('info') } ) > 0
                ? @{ $i->getElementsByTagName('info') }[0]->textContent()
                : undef;
            my $created_at
                = scalar( @{ $i->getElementsByTagName('created-at') } ) > 0
                ? @{ $i->getElementsByTagName('created-at') }[0]
                ->textContent()
                : undef;
            my $mac
                = scalar( @{ $i->getElementsByTagName('mac') } ) > 0
                ? @{ $i->getElementsByTagName('mac') }[0]->textContent()
                : undef;
            my $name
                = scalar( @{ $i->getElementsByTagName('name') } ) > 0
                ? @{ $i->getElementsByTagName('name') }[0]->textContent()
                : undef;
            my $os_flavor
                = scalar( @{ $i->getElementsByTagName('os-flavor') } ) > 0
                ? @{ $i->getElementsByTagName('os-flavor') }[0]->textContent()
                : undef;
            my $os_lang
                = scalar( @{ $i->getElementsByTagName('os-flavor') } ) > 0
                ? @{ $i->getElementsByTagName('os-lang') }[0]->textContent()
                : undef;
            my $os_name
                = scalar( @{ $i->getElementsByTagName('os-name') } ) > 0
                ? @{ $i->getElementsByTagName('os-name') }[0]->textContent()
                : undef;
            my $os_sp
                = scalar( @{ $i->getElementsByTagName('os-sp') } ) > 0
                ? @{ $i->getElementsByTagName('os-sp') }[0]->textContent()
                : undef;
            my $purpose
                = scalar( @{ $i->getElementsByTagName('purpose') } ) > 0
                ? @{ $i->getElementsByTagName('purpose') }[0]->textContent()
                : undef;
            my $state
                = scalar( @{ $i->getElementsByTagName('state') } ) > 0
                ? @{ $i->getElementsByTagName('state') }[0]->textContent()
                : undef;
            my $updated_at
                = scalar( @{ $i->getElementsByTagName('updated-at') } ) > 0
                ? @{ $i->getElementsByTagName('updated-at') }[0]
                ->textContent()
                : undef;
            my $workspace_id
                = scalar( @{ $i->getElementsByTagName('workspace-id') } ) > 0
                ? @{ $i->getElementsByTagName('workspace-id') }[0]
                ->textContent()
                : undef;
            my $host = MetasploitExpress::Parser::Host->new(
                address      => $address,
                address6     => $address6,
                arch         => $arch,
                comm         => $comm,
                comments     => $comments,
                created_at   => $created_at,
                id           => $id,
                info         => $info,
                mac          => $mac,
                name         => $name,
                os_lang      => $os_lang,
                os_name      => $os_name,
                os_flavor    => $os_flavor,
                os_sp        => $os_sp,
                purpose      => $purpose,
                state        => $state,
                updated_at   => $updated_at,
                workspace_id => $workspace_id,
            );
            push( @hosts, $host );
        }

        foreach my $i (
            $xpc->findnodes('//MetasploitExpressV3/services/service') )
        {
            my $service = MetasploitExpress::Parser::Service->new(
                id => scalar( @{ $i->getElementsByTagName('id') } ) > 0
                ? @{ $i->getElementsByTagName('id') }[0]->textContent()
                : undef,
                name => scalar( @{ $i->getElementsByTagName('name') } ) > 0
                ? @{ $i->getElementsByTagName('name') }[0]->textContent()
                : undef,
                host_id => scalar( @{ $i->getElementsByTagName('host-id') } )
                    > 0
                ? @{ $i->getElementsByTagName('host-id') }[0]->textContent()
                : undef,
                info => scalar( @{ $i->getElementsByTagName('info') } ) > 0
                ? @{ $i->getElementsByTagName('info') }[0]->textContent()
                : undef,
                port => scalar( @{ $i->getElementsByTagName('port') } ) > 0
                ? @{ $i->getElementsByTagName('port') }[0]->textContent()
                : undef,
                proto => scalar( @{ $i->getElementsByTagName('proto') } ) > 0
                ? @{ $i->getElementsByTagName('proto') }[0]->textContent()
                : undef,
                state => scalar( @{ $i->getElementsByTagName('state') } ) > 0
                ? @{ $i->getElementsByTagName('state') }[0]->textContent()
                : undef,
                updated_at =>
                    scalar( @{ $i->getElementsByTagName('updated-at') } ) > 0
                ? @{ $i->getElementsByTagName('updated-at') }[0]
                    ->textContent()
                : undef,
                created_at =>
                    scalar( @{ $i->getElementsByTagName('created-at') } ) > 0
                ? @{ $i->getElementsByTagName('created-at') }[0]
                    ->textContent()
                : undef,

            );
            push( @services, $service );
        }

        foreach
            my $i ( $xpc->findnodes('//MetasploitExpressV3/events/event') )
        {
            my $event = MetasploitExpress::Parser::Event->new(
                created_at =>
                    scalar( @{ $i->getElementsByTagName('created-at') } ) > 0
                ? @{ $i->getElementsByTagName('created-at') }[0]
                    ->textContent()
                : undef,
                critical =>
                    scalar( @{ $i->getElementsByTagName('critical') } ) > 0
                ? @{ $i->getElementsByTagName('critical') }[0]->textContent()
                : undef,
                host_id => scalar( @{ $i->getElementsByTagName('host-id') } )
                    > 0
                ? @{ $i->getElementsByTagName('host-id') }[0]->textContent()
                : undef,
                id => scalar( @{ $i->getElementsByTagName('id') } ) > 0
                ? @{ $i->getElementsByTagName('id') }[0]->textContent()
                : undef,
                name => scalar( @{ $i->getElementsByTagName('name') } ) > 0
                ? @{ $i->getElementsByTagName('name') }[0]->textContent()
                : undef,
                seen => scalar( @{ $i->getElementsByTagName('seen') } ) > 0
                ? @{ $i->getElementsByTagName('seen') }[0]->textContent()
                : undef,
                updated_at =>
                    scalar( @{ $i->getElementsByTagName('updated-at') } ) > 0
                ? @{ $i->getElementsByTagName('updated-at') }[0]
                    ->textContent()
                : undef,
                workspace_id =>
                    scalar( @{ $i->getElementsByTagName('workspace-id') } )
                    > 0
                ? @{ $i->getElementsByTagName('workspace-id') }[0]
                    ->textContent()
                : undef,

            );
            push( @events, $event );
        }

        foreach my $i ( $xpc->findnodes('//MetasploitExpressV3/tasks/task') )
        {
            my $task = MetasploitExpress::Parser::Task->new(
                completed_at =>
                    scalar( @{ $i->getElementsByTagName('completed-at') } )
                    > 0
                ? @{ $i->getElementsByTagName('completed-at') }[0]
                    ->textContent()
                : undef,
                created_at =>
                    scalar( @{ $i->getElementsByTagName('created-at') } ) > 0
                ? @{ $i->getElementsByTagName('created-at') }[0]
                    ->textContent()
                : undef,
                created_by =>
                    scalar( @{ $i->getElementsByTagName('created_by') } ) > 0
                ? @{ $i->getElementsByTagName('created_by') }[0]
                    ->textContent()
                : undef,
                description =>
                    scalar( @{ $i->getElementsByTagName('description') } ) > 0
                ? @{ $i->getElementsByTagName('description') }[0]
                    ->textContent()
                : undef,
                error => scalar( @{ $i->getElementsByTagName('error') } ) > 0
                ? @{ $i->getElementsByTagName('error') }[0]->textContent()
                : undef,
                id => scalar( @{ $i->getElementsByTagName('id') } ) > 0
                ? @{ $i->getElementsByTagName('id') }[0]->textContent()
                : undef,
                module => scalar( @{ $i->getElementsByTagName('module') } )
                    > 0
                ? @{ $i->getElementsByTagName('module') }[0]->textContent()
                : undef,
                path => scalar( @{ $i->getElementsByTagName('path') } ) > 0
                ? @{ $i->getElementsByTagName('path') }[0]->textContent()
                : undef,
                progress =>
                    scalar( @{ $i->getElementsByTagName('progress') } ) > 0
                ? @{ $i->getElementsByTagName('progress') }[0]->textContent()
                : undef,
                result => scalar( @{ $i->getElementsByTagName('result') } )
                    > 0
                ? @{ $i->getElementsByTagName('result') }[0]->textContent()
                : undef,
                updated_at =>
                    scalar( @{ $i->getElementsByTagName('updated-at') } ) > 0
                ? @{ $i->getElementsByTagName('updated-at') }[0]
                    ->textContent()
                : undef,
                workspace_id =>
                    scalar( @{ $i->getElementsByTagName('workspace-id') } )
                    > 0
                ? @{ $i->getElementsByTagName('workspace-id') }[0]
                    ->textContent()
                : undef,
            );
            push( @tasks, $task );
        }

        foreach
            my $i ( $xpc->findnodes('//MetasploitExpressV3/reports/report') )
        {
            my $report = MetasploitExpress::Parser::Report->new(
                created_at =>
                    scalar( @{ $i->getElementsByTagName('created-at') } ) > 0
                ? @{ $i->getElementsByTagName('created-at') }[0]
                    ->textContent()
                : undef,
                created_by =>
                    scalar( @{ $i->getElementsByTagName('created-by') } ) > 0
                ? @{ $i->getElementsByTagName('created-by') }[0]
                    ->textContent()
                : undef,
                id => scalar( @{ $i->getElementsByTagName('id') } ) > 0
                ? @{ $i->getElementsByTagName('id') }[0]->textContent()
                : undef,
                path => scalar( @{ $i->getElementsByTagName('path') } ) > 0
                ? @{ $i->getElementsByTagName('path') }[0]->textContent()
                : undef,
                rtype => scalar( @{ $i->getElementsByTagName('rtype') } ) > 0
                ? @{ $i->getElementsByTagName('rtype') }[0]->textContent()
                : undef,
                options => scalar( @{ $i->getElementsByTagName('options') } )
                    > 0
                ? @{ $i->getElementsByTagName('options') }[0]->textContent()
                : undef,
                updated_at =>
                    scalar( @{ $i->getElementsByTagName('updated-at') } ) > 0
                ? @{ $i->getElementsByTagName('updated-at') }[0]
                    ->textContent()
                : undef,
                workspace_id =>
                    scalar( @{ $i->getElementsByTagName('workspace-id') } )
                    > 0
                ? @{ $i->getElementsByTagName('workspace-id') }[0]
                    ->textContent()
                : undef,
                downloaded_at =>
                    scalar( @{ $i->getElementsByTagName('downloaded-at') } )
                    > 0
                ? @{ $i->getElementsByTagName('downloaded-at') }[0]
                    ->textContent()
                : undef,

            );
            push( @reports, $report );
        }

        return MetasploitExpress::Parser::ScanDetails->new(
            hosts    => \@hosts,
            reports  => \@reports,
            tasks    => \@tasks,
            events   => \@events,
            services => \@services,
        );
    }

    sub all_hosts {
        my ($self) = @_;
        my @hosts = @{ $self->hosts };
        return @hosts;
    }

    sub all_services {
        my ($self) = @_;
        my @services = @{ $self->services };
        return @services;
    }

    sub all_events {
        my ($self) = @_;
        my @events = @{ $self->events };
        return @events;
    }

    sub all_tasks {
        my ($self) = @_;
        my @tasks = @{ $self->tasks };
        return @tasks;
    }

    sub all_reports {
        my ($self) = @_;
        my @reports = @{ $self->reports };
        return @reports;
    }
}
1;
