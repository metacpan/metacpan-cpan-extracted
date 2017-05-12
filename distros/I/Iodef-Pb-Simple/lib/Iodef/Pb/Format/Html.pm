package Iodef::Pb::Format::Html;
use base 'Iodef::Pb::Format';

use strict;
use warnings;

use HTML::Table;
use Regexp::Common qw/net/;

my $addr_regex = qr/$RE{'net'}{'IPv4'}|https?|ftp|[a-z0-9._]+\.[a-z]{2,6}/;

sub write_out {
    my $self = shift;
    my $args = shift;
    
    my $array = $self->to_keypair($args);
    
    my $config = $args->{'config'};
    
    my @config_search_path = ('claoverride',  $args->{'query'}, 'client' );

    # fields class evenrowclass oddrowclass display
    
    my $cfg_fields              = $args->{'html_fields'}        || $self->SUPER::confor($config, \@config_search_path, 'html_fields',       undef);
    my $cfg_compress_address    = $args->{'compress_address'}   || $self->SUPER::confor($config, \@config_search_path, 'compress_address',  undef);
    my $cfg_class               = $args->{'html_class'}         || $self->SUPER::confor($config, \@config_search_path, 'html_class',        undef);
    my $cfg_evenrowclass        = $args->{'html_evenrowclass'}  || $self->SUPER::confor($config, \@config_search_path, 'html_evenrowclass', undef);
    my $cfg_oddrowclass         = $args->{'html_oddrowclass'}   || $self->SUPER::confor($config, \@config_search_path, 'html_oddrowclass',  undef);
    my $cfg_uuid                = $args->{'html_uuid'}          || $self->SUPER::confor($config, \@config_search_path, 'html_uuid',         undef);
    my $cfg_relatedid           = $args->{'html_relatedid'}     || $self->SUPER::confor($config, \@config_search_path, 'html_relatedid',    undef);
    my $cfg_html_showmeta       = $args->{'html_showmeta'}      || $self->SUPER::confor($config, \@config_search_path, 'html_showmeta',     undef);
    
    my @cols;
    push(@cols,'id') if($cfg_uuid);
    push(@cols,'relatedid') if($cfg_relatedid);
    push(@cols,(
        'restriction',
        'guid',
        'assessment',
        'description',
        'confidence',
        'detecttime',
        'reporttime',
    ));
   
    # override
    if($cfg_fields){
        @cols = @$cfg_fields;
    }

    my %c;
    unless($cfg_fields){
        foreach my $e (@$array){
            $c{'address'}       = 1 if($e->{'address'});
            $c{'hash'}          = 1 if($e->{'hash'});
            $c{'protocol'}      = 1 if($e->{'protocol'});
            $c{'portlist'}      = 1 if($e->{'portlist'});
            $c{'malware_hash'}  = 1 if($e->{'malware_hash'});
            $c{'rdata'}         = 1 if($e->{'rdata'});
            
            if($cfg_html_showmeta){
                $c{'asn'}                       = 1 if($e->{'asn'});
                $c{'asn_desc'}                  = 1 if($e->{'asn_desc'});
                $c{'prefix'}                    = 1 if($e->{'prefix'});
                $c{'cc'}                        = 1 if($e->{'cc'});
                $c{'rir'}                       = 1 if($e->{'rir'});
                $c{'malware_detection_rate'}    = 1 if($e->{'malware_detection_rate'});
            }
        }
    }
    
    push(@cols,'address')       if($c{'address'});
    push(@cols,'rdata')         if($c{'rdata'});
    push(@cols,'malware_hash')  if($c{'malware_hash'});
    push(@cols,'prefix')        if($c{'prefix'});
    push(@cols,'hash')          if($c{'hash'} && !$c{'address'});
    push(@cols,'protocol')      if($c{'protocol'});
    push(@cols,'portlist')      if($c{'portlist'});

    ## TODO -- make these optional flags passed through
    ## table_showmeta or via the -f option
    if($cfg_html_showmeta && !$cfg_fields){
        push(@cols,'asn') if($c{'asn'});
        push(@cols,'asn_desc') if($c{'asn_desc'});
        push(@cols,'cc') if($c{'cc'});
        push(@cols,'rir') if($c{'rir'});
        push(@cols,'malware_detection_rate'), if($c{'malware_detection_rate'});
    }
    ## TODO -- malware hash lookups?
    
    push(@cols,(
        'alternativeid_restriction',
        'alternativeid',
    )) unless($cfg_fields);
    
    my $table = HTML::Table->new(
        -head           => \@cols,
        -class          => $cfg_class           || '',
        -evenrowclass   => $cfg_evenrowclass    || '',
        -oddrowclass    => $cfg_oddrowclass     || '',
    );
    
    foreach my $e (@$array){
        # work-around for hash searches that don't show the address
        # at some point we'll move this back up the stack to Format.pm
        unless($e->{'address'}){
            for($e->{'description'}){
                if(/search ($addr_regex)$/){
                    $e->{'address'} = $1;
                    last;
                }
            }
        } else {
            if($cfg_compress_address && length($e->{'address'}) > 32){
                $e->{'address'} = substr($e->{'address'},0,31);
                $e->{'address'} .= '...';
            }
        }
        if($cfg_compress_address && length($e->{'description'}) > 32){
            $e->{'description'} = substr($e->{'description'},0,31);
            $e->{'description'} .= '...';
        }
        if($cfg_compress_address && $e->{'alternativeid'} && length($e->{'alternativeid'}) > 75){
            $e->{'alternativeid'} = substr($e->{'alternativeid'},0,74);
            $e->{'alternativeid'} = $e->{'alternativeid'} .= '...';
        }
        if($e->{'alternativeid'} && $e->{'alternativeid'} =~ /[a-zA-Z0-9.-]+\.[a-z]{2,5}/){
            my $addr = ($e->{'alternativeid'} =~ /^http/) ? $e->{'alternativeid'} : 'httmp://'.$e->{'alternativeid'};
            $e->{'alternativeid'} = "<a target='_blank' href='$addr'>$addr</a>";
        }
        $table->addRow(map { $e->{$_} } @cols);

    }
    ## TODO -- what if RestrictionType in Iodef::Pb and FeedType get out of sync?
    my $restriction = $self->convert_restriction($args->{'restriction'}) || 'private';
    if($self->get_group_map && $self->get_group_map->{$args->{'guid'}}){
        $args->{'guid'} = $self->get_group_map->{$args->{'guid'}};
    }
    
    ## TODO - guid should be responded to by the router
    $args->{'uuid'} = '' unless($args->{'uuid'});
    $args->{'guid'} = '' unless($args->{'guid'});

    return $table->getTable();
}

1;
