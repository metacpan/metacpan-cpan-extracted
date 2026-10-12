# ⚠️ Important Warning

**WARNING: This tool will irreversibly erase all existing ID3 tags and replace them with new tags extracted from your directory structure. Always test with the `-n` (dry-run) option first and backup your files before processing!**

**Custom pattern feature is currently experimental and may not work as expected in all cases.**

# Fix MP3 Tags

A fast Perl script to fix MP3 tags based on directory structure.

## Features

- Extracts artist, album, track, and title from directory/filename structure
- Supports flexible date patterns (YYYY*MM)
- Handles CD/Disk subdirectories
- UTF-8 support for international characters
- Dry-run mode for preview
- Fast Perl implementation

## Installation

### From Source
```bash
git clone https://github.com/vr-ski/fix-mp3-tags.git
cd fix-mp3-tags
cpanm --installdeps .
```

### System Requirements
- Perl 5.10 or higher
- MP3::Tag Perl module

## Quick Start

```bash
# Preview what will be changed (dry-run)
./bin/fix-mp3-tags -n

# Process all MP3 files in current directory
./bin/fix-mp3-tags

# Process specific directory
./bin/fix-mp3-tags -d /path/to/music

# Process single file (for testing)
./bin/fix-mp3-tags -f Artist/Album/01.Song.mp3

# Quiet mode (only errors)
./bin/fix-mp3-tags -q
```

## Directory Structure Support

The script supports these directory structures:

### Basic Structure
```
ArtistName/
└── YYYY.MM'AlbumName/
    ├── 01.SongName.mp3
    ├── 02.SongName.mp3
    └── AlbumCover.jpg
```

### With CD/Disk Subdirectories
```
ArtistName/
└── YYYY.MM'AlbumName/
    ├── CD1/
    │   ├── 01.SongName.mp3
    │   └── 02.SongName.mp3
    ├── Disk 2/
    │   ├── 01.SongName.mp3
    │   └── 02.SongName.mp3
    └── [disc_3]/
        ├── 01.SongName.mp3
        └── 02.SongName.mp3
```

### Supported Date Patterns
- `2025.11'AlbumName` → Album: "AlbumName" (2025-11)
- `2020-05 Album Name` → Album: "Album Name" (2020-05)
- `202005AlbumName` → Album: "AlbumName" (2020-05)
- `AlbumName` → Album: "AlbumName" (no date)

## Usage

### Command Line Options
```
-d, --directory DIR     Process all MP3 files in directory DIR (default: current directory)
-f, --file FILE         Process single MP3 file FILE
-q, --quiet             Display only errors
-p, --pattern PATTERN   Custom album directory pattern (regex)
-n, --dry-run           Preview without processing
-v, --version           Show version
-h, --help              Show this help
```

### Examples
```bash
# Preview with custom pattern
./bin/fix-mp3-tags -n -p "^([0-9]{4})-([0-9]{2})\s+(.+)$"

# Process with custom pattern
./bin/fix-mp3-tags -p "^([0-9]{4})_([0-9]{2})_(.*)"

# Test single file quietly
./bin/fix-mp3-tags -q -f "Artist/2000.11'Debut Album/01.Hit Single.mp3"
```

## Development

### Installing Dependencies
```bash
cpanm --installdeps --with-develop .
```

### Running Tests
```bash
prove -l t/
```

### Code Quality
```bash
# Lint
perlcritic bin/fix-mp3-tags lib/

# Format code
perltidy bin/fix-mp3-tags lib/
```

### Pre-commit Hooks
```bash
pre-commit install
pre-commit run --all-files
```

## How It Works

| Tag | Extracted from |
|---|---|
| **Artist** | Parent directory name |
| **Album** | Directory name (supports various date patterns) |
| **Track Number** | Filename (`NN.SongName` pattern) |
| **Title** | Filename (cleaned up) |
| **Year/Month** | Directory name, if present |

## License

BSD 2-Clause License - see LICENSE file for details.
