---
name: vast-ai-cli
description: "vastai CLI tool — search GPU offers, launch/create/manage/destroy instances, volumes, templates"
user-invocable: false
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

# vastai CLI

Binary at `/storage/raid/home/getty/python/bin/vastai`. API key stored at `~/.config/vastai/vast_api_key`.

Global flags: `--raw` (JSON output), `--explain` (show REST call), `--api-key KEY`.

## Search Offers

```bash
# RTX 4090, reliable, on-demand
vastai search offers 'gpu_name=RTX_4090 num_gpus=1 reliability>0.98'

# Multi-GPU, datacenter only, sorted by price
vastai search offers 'num_gpus>=4 datacenter=True gpu_ram>=24' -o 'dph'

# Specific region, exclude countries
vastai search offers 'gpu_name=H100_SXM num_gpus>=8 geolocation notin [CN,VN]'

# Interruptible/spot pricing
vastai search offers 'gpu_name=RTX_4090' --type=bid
```

**Query syntax:** `field op value` — ops: `<`, `<=`, `==`, `!=`, `>=`, `>`, `in`, `notin`
**GPU names:** underscores not spaces: `RTX_4090`, `H100_SXM`, `A100_SXM4`

Key fields: `gpu_name`, `num_gpus`, `gpu_ram`, `reliability`, `dph` ($/hr), `datacenter`, `geolocation`, `cuda_vers`, `disk_space`, `duration`, `direct_port_count`, `inet_down`, `total_flops`

## Launch Instance (search + create in one)

```bash
# Simplest — picks best offer automatically
vastai launch instance -g RTX_4090 -n 1 -i pytorch/pytorch --ssh --direct

# With disk and region
vastai launch instance -g RTX_3090 -n 4 -i pytorch/pytorch -d 64 -r North_America --ssh --direct
```

## Create Instance (from offer ID)

```bash
# Get offer ID from search first
vastai search offers 'gpu_name=RTX_4090 num_gpus=1 reliability>0.98'

# Create from offer ID
vastai create instance 384826 --image pytorch/pytorch --disk 40 --ssh --direct

# With env vars, ports, onstart script
vastai create instance 384826 \
  --image myregistry/myimage:latest \
  --login '-u user -p token docker.io' \
  --disk 64 --ssh --direct \
  --env '-e HF_TOKEN=hf_xxx -e MODEL=llama3 -p 8080:8080' \
  --onstart-cmd 'cd /workspace && bash setup.sh'

# From template
vastai create instance 384826 --template_hash 661d064bbda1f2a133816b6d55da07c3 --disk 64

# Interruptible (spot) with bid price
vastai create instance 384826 --image pytorch/pytorch --disk 40 --bid_price 0.10
```

**Launch modes:**
- `--ssh --direct` — SSH, direct connection (fastest)
- `--ssh` — SSH via Vast proxy
- `--jupyter --direct` — Jupyter + SSH, direct
- No flag + `--args` — preserves image entrypoint, args as CMD

## Manage Instances

```bash
vastai show instances              # List all
vastai show instance 12345         # Details
vastai stop instance 12345         # Stop (keeps storage, no GPU charges)
vastai start instance 12345        # Restart stopped instance
vastai reboot instance 12345       # Stop + start
vastai label instance 12345 "my-job"
vastai destroy instance 12345      # Irreversible, deletes data
vastai logs 12345                  # Container logs
```

## SSH Access

```bash
vastai ssh-url 12345               # Print SSH command
vastai scp-url 12345               # Print SCP command
vastai attach ssh 12345 KEY_ID     # Attach SSH key
```

## Volumes

```bash
vastai show volumes
vastai create volume ...
vastai delete volume 123
```

Attach to instance: `vastai create instance ID ... --env '-v /volume:/workspace'`

## Templates

```bash
vastai search templates 'query'
vastai create template ...
vastai delete template 123
```

## Serverless Endpoints

```bash
vastai create endpoint ...
vastai show endpoints
vastai delete endpoint 123
vastai get endpt-logs 123
```

## Data Transfer

```bash
vastai copy SRC_ID:/path DST_ID:/path
vastai cloud copy ...
vastai cancel copy ID
```

## Useful Patterns

```bash
# JSON output for scripting
vastai show instances --raw | jq '.[] | {id, gpu_name, status: .actual_status, dph: .dph_total}'

# See what REST call the CLI makes
vastai search offers 'gpu_name=RTX_4090' --explain

# Destroy all instances
vastai show instances --raw | jq '.[].id' | xargs -I{} vastai destroy instance {}
```
