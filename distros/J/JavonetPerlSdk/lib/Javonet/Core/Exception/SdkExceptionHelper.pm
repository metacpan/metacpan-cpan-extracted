use strict;
use warnings;
use LWP::UserAgent;
use DateTime;
use Sys::Hostname;
use threads;
use Nice::Try;

my $address = "https://dc.services.visualstudio.com/v2/track";
my $instrumentationKey = "2c751560-90c8-40e9-b5dd-534566514723";

package Javonet::Core::Exception::SdkExceptionHelper;

sub send_exception_to_app_insights {
    my ($class, $event, $license_key) = @_;
    try {
        my $ua = LWP::UserAgent->new;
        $ua->default_header('Accept' => 'application/json');

        # Path to the VERSION file
        my $version_file_path = 'VERSION';

        # Variable to hold the javonet version
        my $javonet_version;

        try {
            # Open the VERSION file for reading
            open(my $fh, '<', $version_file_path) or die "Could not open file '$version_file_path' $!";

            # Read the first line of the file
            my $first_line = <$fh>;

            # Use a regular expression to extract the version number
            if ($first_line =~ /^\$VERSION=(.+)$/) {
                $javonet_version = $1;
            }

            # Close the file handle
            close($fh);
        }
        catch ( $e ) {
            $javonet_version = "2.0.0";
        }

        my $node_name = eval {hostname()} || "Unknown Host";

        my $operation_name = "JavonetSdkException";
        my $os_name = $^O;                 # Replace with your desired OS name
        my $calling_runtime_name = "Perl"; # Replace with your desired runtime name
        my $event_message = $event;

        my $dt = DateTime->now(time_zone => 'GMT');

        # Format the DateTime object to a string
        my $formatted_datetime = $dt->strftime("%Y-%m-%dT%H:%M:%S");

        my $payload = "{"
            . "\"name\": \"AppEvents\","
            . "\"time\": \"$formatted_datetime\","
            . "\"iKey\": \"$instrumentationKey\","
            . "\"tags\": {"
            . "\"ai.application.ver\": \"$javonet_version\","
            . "\"ai.cloud.roleInstance\": \"$node_name\","
            . "\"ai.operation.id\": \"0\","
            . "\"ai.operation.parentId\": \"0\","
            . "\"ai.operation.name\": \"$operation_name\","
            . "\"ai.internal.sdkVersion\": \"$javonet_version\","
            . "\"ai.internal.nodeName\": \"$node_name\""
            . "},"
            . "\"data\": {"
            . "\"baseType\": \"EventData\","
            . "\"baseData\": {"
            . "\"ver\": 2,"
            . "\"name\": \"$event_message\","
            . "\"properties\": {"
            . "\"OperatingSystem\": \"$os_name\","
            . "\"LicenseKey\": \"$license_key\","
            . "\"CallingTechnology\": \"$calling_runtime_name\""
            . "}"
            . "}"
            . "}"
            . "}";

        my $response = $ua->post($address, Content => $payload);
        my $response_code = $response->code;
        return $response_code;
    }
    catch ( $e ) {
        return Exception->new($e);
    }
}

1;