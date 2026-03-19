---
name: vast-ai
description: "Vast.ai GPU cloud API — search offers, create/manage instances, volumes, serverless endpoints, templates"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Vast.ai GPU Cloud API

## Authentication

```
Authorization: Bearer <API_KEY>
```

API keys from L<https://cloud.vast.ai/cli/>. Restricted keys possible with permission scoping.

## Base URL

```
https://console.vast.ai/api/v0/
```

## Core Workflow: Search → Create → Manage → Destroy

### 1. Search Offers

```
POST /bundles/
```

```json
{
  "gpu_name": {"in": ["RTX 4090"]},
  "num_gpus": {"gte": 1},
  "gpu_ram": {"gte": 24000},
  "reliability": {"gte": 0.99},
  "verified": {"eq": true},
  "rentable": {"eq": true},
  "type": "ondemand",
  "limit": 5
}
```

Operators: `in` (list), `gte`/`lte` (range), `eq` (exact).

Returns offers with: `id`, `gpu_name`, `num_gpus`, `dph_total` ($/hr), reliability, compute caps.

### 2. Create Instance

```
PUT /asks/{offer_id}/
```

```json
{
  "image": "pytorch/pytorch:latest",
  "disk": 20,
  "runtype": "ssh_direct",
  "env": {
    "HF_TOKEN": "hf_xxx",
    "-p 8080:8080": "1"
  },
  "onstart": "cd /workspace && bash setup.sh"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `image` | string | Docker image (required unless template) |
| `disk` | number | Local disk GB (default 8) |
| `runtype` | string | `ssh_direct`, `ssh_proxy`, `jupyter_direct`, `jupyter_proxy`, `args` |
| `target_state` | string | `running` (default) or `stopped` |
| `price` | number | Bid $/hr (for interruptible/bid type) |
| `env` | object | Env vars + port mappings (`"-p 8080:8080": "1"`) |
| `onstart` | string | Shell commands after init |
| `args_str` | string | Replace CMD (for `args` runtype) |
| `template_hash_id` | string | Pre-configured template |
| `label` | string | Custom instance name |
| `image_login` | string | Private registry: `"-u user -p token registry"` |
| `volume_info` | object | `{"volume_id": 123, "mount_path": "/workspace"}` |

**Runtypes:**
- `ssh_direct` / `ssh_proxy` — SSH access, Vast entrypoint replaces image entrypoint
- `jupyter_direct` / `jupyter_proxy` — Jupyter + SSH, Vast entrypoint replaces image entrypoint
- `args` — Preserves original image entrypoint, `args_str` as arguments

Response: `{"success": true, "new_contract": 12345}`

### 3. Manage Instance

```
PUT /instances/{id}/
```

```json
{"state": "stopped"}   // or "running"
```

### 4. Destroy Instance

```
DELETE /instances/{id}/
```

### 5. Show Instance(s)

```
GET /instances/{id}/    // single
GET /instances/         // list all
```

## Volumes

```
POST   /volumes/              // create
GET    /volumes/              // list
DELETE /volumes/{id}/         // delete
```

Attach to instance via `volume_info` in create request.

## Serverless Endpoints

### Create Endpoint

```
POST /endptjobs/
```

Scaling config: `min_load`, `target_util`, `cold_mult`, `cold_workers`, `max_workers`.

### Create Workergroup

```
POST /workergroups/
```

Requires `endpoint_id` or `endpoint_name` + template or search params.

### Manage

```
GET    /endptjobs/            // list endpoints
DELETE /endptjobs/{id}/       // delete endpoint
GET    /endptjobs/{id}/logs/  // get logs
```

## Other Endpoints

| Resource | CRUD |
|----------|------|
| SSH Keys | `POST/GET/PUT/DELETE /ssh-keys/` |
| API Keys | `POST/GET/DELETE /api-keys/` |
| Templates | `POST/PUT/DELETE /templates/` |
| Autoscalers | `POST/GET/PUT/DELETE /autoscalers/` |
| Teams | `POST/DELETE /teams/`, members, roles |
| Env Vars | `POST/GET/PUT/DELETE /env-vars/` |

## Instance Logs & SSH

```
GET /instances/{id}/logs/     // container logs
GET /instances/{id}/ssh-url/  // SSH connection string
```

## CLI Tip

Use `vastai <command> --explain` to see the underlying REST API call.

## Billing

- Storage charges begin at creation
- GPU charges begin when instance is `running`
- `stop` preserves storage, eliminates GPU charges
- `destroy` eliminates all charges
