use FindBin::libs;
use Eliza::Chatbot;
my $bot = Eliza::Chatbot->new();
$bot->command_interface;

1;
