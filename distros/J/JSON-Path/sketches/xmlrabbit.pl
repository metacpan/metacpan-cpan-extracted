use 5.016;

package Model::Advert { 
    use XML::Rabbit;

    has_xpath_value id => './Id';
    has_xpath_value job_title => './JobTitle';
    finalize_class();
};

package Model::StatusCheckResponse { 
    use XML::Rabbit; 

    has_xpath_object advert => '//Advert' => 'Model::Advert';
    finalize_class();
};

package Model { 
    use XML::Rabbit::Root;

    has_xpath_object 'status_check_response' => '//StatusCheckResponse' => 'Model::StatusCheckResponse';
    finalize_class();
};

my $xml = q(<?xml version="1.0" encoding="utf-8"?>

<AdCourierAPIResponse>
    <TimeNow>2017-06-22T01:26:06Z</TimeNow>
    <ResponseId>tegna-2017-06-22T01-26-06-StatusCheck-prod-gs-api-1-113612-180568</ResponseId>
    <StatusCheckResponse>
        <Advert>
            <Id>01441</Id>
            <CreateTime>2017-06-22T01:25:34Z</CreateTime>
            <Consultant>rmcdonald</Consultant>
            <Team>tegna</Team>
            <Office>est</Office>
            <UserName>rmcdonald@tegna.est.tegna</UserName>
            <JobTitle>Account Executive - New Business Developer</JobTitle>
            <JobReference>1945/2517</JobReference>
            <JobType>Permanent</JobType>
            <CustomField name="luceo_advert_id">2517</CustomField>
            <CustomField name="luceo_client_id">tegna</CustomField>
            <CustomField name="luceo_position_id">1945</CustomField>
            <CustomField name="luceo_reference_id">TEGNA Media-001945/4</CustomField>
            <CustomField name="luceo_user_id">3388</CustomField>
        </Advert>
        <ChannelList>
            <Channel>
                <ChannelId>careerbuilder_usonly</ChannelId>
                <ChannelName>CareerBuilder (North America)</ChannelName>
                <ChannelStatus PostedTime="2017-05-26T01:19:32Z" RemovalTime="2017-06-25T04:59:59Z" AdvertURL="http://www.careerbuilder.com/jobseeker/jobs/RedirectAOL.aspx?show=yes&amp;job_did=J3L6FV69XHB3MZP0V3R" Responses="55" ReturnCode="0" ReturnCodeClass="Success">Sent</ChannelStatus>
            </Channel>
            <Channel>
                <ChannelId>juju</ChannelId>
                <ChannelName>JuJu (Job Search Engine)</ChannelName>
                <ChannelStatus PostedTime="2017-06-22T01:25:38Z" RemovalTime="2017-07-20T01:25:38Z" Responses="0" ReturnCode="0" ReturnCodeClass="Success">Sent</ChannelStatus>
            </Channel>
            <Channel>
                <ChannelId>myjobhelper</ChannelId>
                <ChannelName>MyJobHelper</ChannelName>
                <ChannelStatus PostedTime="2017-04-25T23:53:47Z" RemovalTime="2017-06-24T23:53:47Z" Responses="0" ReturnCode="0" ReturnCodeClass="Success">Sent</ChannelStatus>
            </Channel>
            <Channel>
                <ChannelId>simplyhired</ChannelId>
                <ChannelName>The Broadbean Network</ChannelName>
                <ChannelStatus PostedTime="2017-04-25T23:53:48Z" RemovalTime="2017-05-25T23:53:48Z" Responses="0" ReturnCode="6" ReturnCodeClass="Success">Expired</ChannelStatus>
            </Channel>
        </ChannelList>
    </StatusCheckResponse>
</AdCourierAPIResponse>);

use JSON::Path;
my $model = Model->new( xml => $xml );
say for @Model::ISA;
say $model->status_check_response->advert->job_title;
