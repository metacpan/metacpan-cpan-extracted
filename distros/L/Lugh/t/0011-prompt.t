#!/usr/bin/env perl
# t/11-prompt.t - Test prompt template formatting (XS)

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use lib "$Bin/../lib";
use lib "$Bin/../blib/lib";
use lib "$Bin/../blib/arch";

use_ok('Lugh::Prompt');

# Test available formats
my @formats = Lugh::Prompt->available_formats;
ok(@formats >= 9, "Multiple formats available: " . join(', ', @formats));
ok(Lugh::Prompt->has_format('chatml'), 'chatml format available');
ok(Lugh::Prompt->has_format('llama2'), 'llama2 format available');

# Test ChatML format
subtest 'ChatML format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'chatml');
    is($prompt->format_name, 'chatml', 'Format name is chatml');
    
    my $text = $prompt->apply(
        { role => 'system', content => 'You are helpful.' },
        { role => 'user',   content => 'Hello!' },
        add_bos => 0,
    );
    
    like($text, qr/<\|im_start\|>system/, 'Has system start');
    like($text, qr/You are helpful\./, 'Has system content');
    like($text, qr/<\|im_end\|>/, 'Has end token');
    like($text, qr/<\|im_start\|>user/, 'Has user start');
    like($text, qr/Hello!/, 'Has user content');
    like($text, qr/<\|im_start\|>assistant\n$/, 'Ends with assistant prompt');
};

# Test Llama 2 format
subtest 'Llama 2 format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'llama2');
    is($prompt->format_name, 'llama2', 'Format name is llama2');
    
    my $text = $prompt->apply(
        { role => 'system', content => 'You are helpful.' },
        { role => 'user',   content => 'Hello!' },
        add_bos => 0,
    );
    
    like($text, qr/\[INST\]/, 'Has INST tag');
    like($text, qr/<<SYS>>/, 'Has SYS tag');
    like($text, qr/You are helpful\./, 'Has system content');
    like($text, qr/<\/SYS>>/, 'Has closing SYS tag');
    like($text, qr/Hello!/, 'Has user content');
    like($text, qr/\[\/INST\]/, 'Has closing INST tag');
};

# Test Llama 3 format
subtest 'Llama 3 format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'llama3');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' }
    );
    
    like($text, qr/<\|begin_of_text\|>/, 'Has BOS token');
    like($text, qr/<\|start_header_id\|>user<\|end_header_id\|>/, 'Has user header');
    like($text, qr/Hello!/, 'Has user content');
    like($text, qr/<\|eot_id\|>/, 'Has EOT token');
    like($text, qr/<\|start_header_id\|>assistant<\|end_header_id\|>/, 'Has assistant header');
};

# Test Mistral format
subtest 'Mistral format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'mistral');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' }
    );
    
    like($text, qr/^<s>/, 'Starts with BOS');
    like($text, qr/\[INST\] Hello! \[\/INST\]/, 'Has INST wrapped content');
};

# Test Gemma format
subtest 'Gemma format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'gemma');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' }
    );
    
    like($text, qr/<bos>/, 'Has BOS token');
    like($text, qr/<start_of_turn>user/, 'Has user turn start');
    like($text, qr/Hello!/, 'Has user content');
    like($text, qr/<end_of_turn>/, 'Has turn end');
    like($text, qr/<start_of_turn>model/, 'Has model turn');
};

# Test Zephyr format
subtest 'Zephyr format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'zephyr');
    
    my $text = $prompt->apply(
        { role => 'system', content => 'Be helpful.' },
        { role => 'user', content => 'Hello!' }
    );
    
    like($text, qr/<\|system\|>/, 'Has system tag');
    like($text, qr/<\|user\|>/, 'Has user tag');
    like($text, qr/<\|assistant\|>/, 'Has assistant tag');
};

# Test multi-turn conversation
subtest 'Multi-turn conversation' => sub {
    my $prompt = Lugh::Prompt->new(format => 'chatml');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' },
        { role => 'assistant', content => 'Hi there!' },
        { role => 'user', content => 'How are you?' },
        add_bos => 0,
    );
    
    like($text, qr/Hello!/, 'First user message');
    like($text, qr/Hi there!/, 'Assistant response');
    like($text, qr/How are you\?/, 'Second user message');
    # Should end with generation prompt
    like($text, qr/<\|im_start\|>assistant\n$/, 'Ends with generation prompt');
};

# Test without generation prompt
subtest 'Without generation prompt' => sub {
    my $prompt = Lugh::Prompt->new(format => 'chatml');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' },
        add_generation_prompt => 0,
        add_bos => 0,
    );
    
    unlike($text, qr/<\|im_start\|>assistant\n$/, 'No assistant prompt at end');
    like($text, qr/<\|im_end\|>\n$/, 'Ends with user message end');
};

# Test architecture detection
subtest 'Architecture detection' => sub {
    is(Lugh::Prompt->format_for_architecture('qwen2'), 'chatml', 'qwen2 -> chatml');
    is(Lugh::Prompt->format_for_architecture('phi3'), 'chatml', 'phi3 -> chatml');
    is(Lugh::Prompt->format_for_architecture('llama'), 'llama2', 'llama -> llama2');
    is(Lugh::Prompt->format_for_architecture('gemma'), 'gemma', 'gemma -> gemma');
    is(Lugh::Prompt->format_for_architecture('mistral'), 'mistral', 'mistral -> mistral');
    is(Lugh::Prompt->format_for_architecture('unknown'), 'chatml', 'unknown -> chatml (default)');
};

# Test shortcut functions
subtest 'Shortcut functions' => sub {
    my $chatml = Lugh::Prompt::chatml({ role => 'user', content => 'Test' });
    like($chatml, qr/<\|im_start\|>/, 'chatml() shortcut works');
    
    my $llama3 = Lugh::Prompt::llama3({ role => 'user', content => 'Test' });
    like($llama3, qr/<\|begin_of_text\|>/, 'llama3() shortcut works');
};

# Test system to user prepending (for formats that don't support system role)
subtest 'System to user prepending' => sub {
    my $prompt = Lugh::Prompt->new(format => 'gemma');
    
    my $text = $prompt->apply(
        { role => 'system', content => 'Be helpful.' },
        { role => 'user', content => 'Hello!' }
    );
    
    # System should be prepended to first user message in Gemma
    like($text, qr/Be helpful\.\n\nHello!/, 'System prepended to user in Gemma');
};

# Test Alpaca format
subtest 'Alpaca format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'alpaca');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'What is 2+2?' }
    );
    
    like($text, qr/### Instruction:/, 'Has instruction header');
    like($text, qr/What is 2\+2\?/, 'Has question');
    like($text, qr/### Response:/, 'Has response header');
};

# Test Vicuna format
subtest 'Vicuna format' => sub {
    my $prompt = Lugh::Prompt->new(format => 'vicuna');
    
    my $text = $prompt->apply(
        { role => 'user', content => 'Hello!' }
    );
    
    like($text, qr/USER: /, 'Has USER: prefix');
    like($text, qr/ASSISTANT: /, 'Has ASSISTANT: prefix');
};

# Test get_format returns format info
subtest 'Get format info' => sub {
    my $fmt = Lugh::Prompt->get_format('chatml');
    ok(ref($fmt) eq 'HASH', 'get_format returns hashref');
    is($fmt->{name}, 'chatml', 'Has correct name');
    ok(exists $fmt->{system_prefix}, 'Has system_prefix');
    ok(exists $fmt->{user_prefix}, 'Has user_prefix');
    ok(exists $fmt->{assistant_prefix}, 'Has assistant_prefix');
};

done_testing();
